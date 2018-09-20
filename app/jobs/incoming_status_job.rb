class IncomingStatusJob < ApplicationJob
  include Rails.application.routes.url_helpers

  FINALIZED_STATUSES = %w[delivered undelivered failed].freeze
  ERRORED_STATUSES = %w[undelivered failed].freeze

  queue_as :high_priority

  # rubocop:disable Metrics/PerceivedComplexity
  def perform(params:)
    message = Message.find_by twilio_sid: params[:SmsSid]
    return if message.nil?

    Rails.logger.tagged('incoming_sms_status') { Rails.logger.warn "#{params[:SmsSid]} - #{params[:heroku_request_start]} ... params[:SmsStatus]: #{params[:SmsStatus]}" }

    heroku_request_start = params[:heroku_request_start]
    message_current_status = message.twilio_status
    message_incoming_status = params[:SmsStatus]
    status_out_of_order = FINALIZED_STATUSES.exclude?(message_incoming_status) && FINALIZED_STATUSES.include?(message_current_status)
    return if status_out_of_order

    status_override = FINALIZED_STATUSES.include?(message_incoming_status) && FINALIZED_STATUSES.exclude?(message_current_status)

    return unless !message.last_twilio_update || status_override || heroku_request_start > message.last_twilio_update

    message.with_lock do
      message.update!(twilio_status: message_incoming_status, last_twilio_update: heroku_request_start)

      MessageBroadcastJob.perform_later(message: message)

      if message_incoming_status == 'delivered'
        message.reporting_relationship.update!(has_message_error: false)
      elsif ERRORED_STATUSES.include?(message_incoming_status)
        message.reporting_relationship.update!(has_message_error: true)
        analytics_track(
          label: 'message_send_failed',
          data: message.analytics_tracker_data
        )
      end
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
end
