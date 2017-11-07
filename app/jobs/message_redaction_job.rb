class MessageRedactionJob < ApplicationJob
  queue_as :default

  def perform(message:)
    retry_job unless SMSService.instance.redact_message(message: message)
  end
end
