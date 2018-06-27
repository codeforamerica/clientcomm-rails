class MessageRedactionJob < ApplicationJob
  class TwilioNotFound < StandardError; end
  class TwilioNotComplete < StandardError; end

  queue_as :default

  retry_on Twilio::REST::RestError, wait: :exponentially_longer
  retry_on Faraday::ConnectionFailed, wait: :exponentially_longer

  def perform(message:)
    Rails.logger.warn "[MESSAGE_REDACTION_JOB] redacting message #{message.id}"
    SMSService.instance.redact_message(message: message)
  end
end
