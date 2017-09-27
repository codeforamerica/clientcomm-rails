require 'singleton'

class SMSService
  include AnalyticsHelper
  include Singleton

  def initialize
    sid = ENV['TWILIO_ACCOUNT_SID']
    token = ENV['TWILIO_AUTH_TOKEN']
    @client = Twilio::REST::Client.new sid, token
  end

  def send_message(message:, callback_url:)
    # send the message via Twilio
    response = send_twilio_message(
      to: message.client.phone_number,
      body: message.body,
      callback_url: callback_url
    )

    message.update!(
      twilio_sid: response.sid,
      twilio_status: response.status
    )

    MessageBroadcastJob.perform_now(message: message)
  end

  def redact_message(message:)
    message = @client.api.account.messages(message.twilio_sid).fetch
    message.update(body: '')

    true
  rescue Twilio::REST::RestError => e
    raise e unless e.code == 20009
    false
  end

  private

  def send_twilio_message(to:, body:, callback_url:)
    to_clean = PhoneNumberParser.normalize(to)
    # use the from in the ENV if one wasn't sent
    from = PhoneNumberParser.normalize(ENV['TWILIO_PHONE_NUMBER'])
    @client.api.account.messages.create(
        from: from,
        to: to_clean,
        body: body,
        status_callback: callback_url
    )
  end
end
