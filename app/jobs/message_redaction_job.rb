class TwilioNotFound < StandardError; end

class MessageRedactionJob < ApplicationJob
  queue_as :default

  retry_on TwilioNotFound

  def perform(message:)
    SMSService.instance.redact_message(message: message)
  rescue Twilio::REST::RestError => e
    raise TwilioNotFound if e.code == 20404
    raise e
  end
end
