class MessageRedactionJob < ApplicationJob
  class TwilioNotFound < StandardError; end
  class TwilioNotComplete < StandardError; end

  queue_as :low_priority

  retry_on Twilio::REST::RestError, wait: ->(executions) { 240 * executions * executions }
  retry_on Faraday::ConnectionFailed, wait: :exponentially_longer

  def perform(message:)
    Rails.logger.warn "[MESSAGE_REDACTION_JOB] redacting message #{message.id}"
    SMSService.instance.redact_message(message: message)
  end
end
