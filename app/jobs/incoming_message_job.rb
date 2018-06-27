class IncomingMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(params:)
    new_message = Message.create_from_twilio! params
    client = new_message.client

    rr = new_message.reporting_relationship

    client_previously_active = rr.active

    rr.update!(
      last_contacted_at: new_message.send_at,
      has_unread_messages: true,
      has_message_error: false,
      active: true
    )

    MessageRedactionJob.perform_later(message: new_message)

    # queue message and notification broadcasts
    MessageBroadcastJob.perform_later(message: new_message)

    # construct and queue an alert
    message_alert = MessageAlertBuilder.build_alert(
      reporting_relationship: rr,
      reporting_relationship_path: reporting_relationship_path(rr),
      clients_path: clients_path
    )

    NotificationBroadcastJob.perform_later(
      channel_id: new_message.user.id,
      text: message_alert[:text],
      link_to: message_alert[:link_to],
      properties: { client_id: client.id }
    )

    NotificationMailer.message_notification(new_message.user, new_message).deliver_later if new_message.user.message_notification_emails

    track(
      label: 'message_receive',
      user_id: rr.user.id,
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
