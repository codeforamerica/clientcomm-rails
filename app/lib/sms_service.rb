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

    message.twilio_sid = response.sid
    message.twilio_status = response.status
    # put the message broadcast in the queue
    MessageBroadcastJob.perform_now(message: message, is_update: false)

  end

  def schedule_message(user, client_id, message_body, callback_url:)
    ScheduledMessageJob.set(wait: 5.seconds).perform_later(user: user, client_id: client_id, message_body: message_body, callback_url: callback_url)
  end

  private

  def send_twilio_message(from: nil, to:, body:, callback_url:)
    to_clean = PhoneNumberParser.normalize(to)
    # use the from in the ENV if one wasn't sent
    from ||= ENV['TWILIO_PHONE_NUMBER']
    from_clean = PhoneNumberParser.normalize(from)
    @client.account.messages.create(
        from: from_clean,
        to: to_clean,
        body: body,
        statusCallback: callback_url
    )
  end
end
