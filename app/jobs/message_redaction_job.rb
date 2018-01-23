class MessageRedactionJob < ApplicationJob
  queue_as :default

  def perform(message:)
    SMSService.instance.redact_message(message: message)
  end
end
