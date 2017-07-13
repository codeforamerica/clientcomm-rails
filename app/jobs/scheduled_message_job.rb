class ScheduledMessageJob < ApplicationJob
  include ActionView::RecordIdentifier
  include AnalyticsHelper

  queue_as :default

  def perform(message:, callback_url:)
    SMSService.instance.send_message(
        message: message,
        callback_url: callback_url
    )

    # track the message send
    label = 'message_send'
    if ['failed', 'undelivered'].include?(message.twilio_status)
      label = 'message_send_failed'
    end

    analytics_track(
      label: label,
      data: message.analytics_tracker_data
    )
  end
end
