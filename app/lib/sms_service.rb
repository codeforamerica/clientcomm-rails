require 'singleton'
require 'erb'

MessageInfo = Struct.new(:sid, :status)

class SMSService
  include AnalyticsHelper
  include Singleton

  class NumberNotFound < StandardError; end

  def initialize
    sid = ENV['TWILIO_ACCOUNT_SID']
    token = ENV['TWILIO_AUTH_TOKEN']
    @client = Twilio::REST::Client.new sid, token
  end

  def status_lookup(message:)
    message_lookup(twilio_sid: message.twilio_sid).status
  end

  def message_lookup(twilio_sid:)
    @client.api.account.messages(twilio_sid).fetch
  end

  def send_message(args)
    # send the message via Twilio
    response = @client.api.account.messages.create(args)

    MessageInfo.new(response.sid, response.status)
  end

  def redact_message(message:)
    Rails.logger.tagged('redact message') { Rails.logger.warn "redacting #{message.id}" }
    twilio_message = @client.api.account.messages(message.twilio_sid).fetch
    twilio_message.update(body: '')

    Rails.logger.tagged('redact message') { Rails.logger.warn "deleting #{twilio_message.num_media} media items from message #{message.id}" }
    twilio_message.media.list.each(&:delete) if twilio_message.num_media != '0'

    true
  rescue Twilio::REST::RestError => e
    raise e unless e.code == 20009
    false
  end

  def number_lookup(phone_number:)
    @client.lookups.v1.phone_numbers(ERB::Util.url_encode(phone_number)).fetch.phone_number
  rescue Twilio::REST::RestError => e
    if e.code == 20404
      raise NumberNotFound
    else
      raise e
    end
  end
end
