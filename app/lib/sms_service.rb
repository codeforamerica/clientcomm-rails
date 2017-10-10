require 'singleton'
require 'erb'

class SMSService
  include AnalyticsHelper
  include Singleton

  class NumberNotFound < StandardError; end

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

    if message.num_media != '0'
      message.media.list.each do |media|
        media.delete
      end
    end

    true
  rescue Twilio::REST::RestError => e
    raise e unless e.code == 20009
    false
  end

  def number_lookup(phone_number:)
    @client.lookups.v1.phone_numbers(ERB::Util.url_encode(phone_number)).fetch.phone_number
  rescue Twilio::REST::RestError => e
    raise e unless e.code == 20404
    raise NumberNotFound
  end

  private

  def send_twilio_message(to:, body:, callback_url:)
    @client.api.account.messages.create(
        from: ENV['TWILIO_PHONE_NUMBER'],
        to: to,
        body: body,
        status_callback: callback_url
    )
  end
end
