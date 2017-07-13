class ScheduledMessageJob < ApplicationJob
  include ActionView::RecordIdentifier
  include AnalyticsHelper

  queue_as :default

  def perform(message:, callback_url:)
    SMSService.instance.send_message(
        message: message,
        callback_url: callback_url
    )
  end
end
