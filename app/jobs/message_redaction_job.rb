class MessageRedactionJob < ApplicationJob
  class TwilioNotFound < StandardError; end
  class TwilioNotComplete < StandardError; end

  queue_as :default

  retry_on TwilioNotFound, wait: :exponentially_longer
  retry_on TwilioNotComplete, wait: :exponentially_longer
  retry_on Faraday::ConnectionFailed, wait: :exponentially_longer

  def perform(message:)
    SMSService.instance.redact_message(message: message)
  rescue Twilio::REST::RestError => e
    raise TwilioNotFound if e.code == 20404
    raise TwilioNotComplete if e.code == 20009
    raise e
  end
end
