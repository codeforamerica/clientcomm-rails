class IncomingMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :high_priority

  def perform(params:)
    new_message = Message.create_from_twilio! params
    client_previously_active = new_message.reporting_relationship.active
    MessageHandler.handle_new_message(message: new_message)

    track(
      label: 'message_receive',
      user_id: new_message.reporting_relationship.user.id,
      data: new_message.analytics_tracker_data.merge(client_active: client_previously_active)
    )
  end

  private

  def track(label:, user_id:, data: {})
    tracking_data = {
      deploy: deploy_prefix
    }.merge(data)
    AnalyticsService.track(
      label: label,
      distinct_id: distinct_id(user_id),
      data: tracking_data
    )
  end

  def deploy_prefix
    URI.parse(ENV['DEPLOY_BASE_URL']).hostname.split('.')[0..1].join('_')
  end

  def distinct_id(user_id)
    "#{deploy_prefix}-#{user_id}"
  end
end
