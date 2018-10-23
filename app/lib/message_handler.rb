class MessageHandler
  def self.handle_new_message(message:)
    client = message.client

    rr = message.reporting_relationship

    rr.update!(
      last_contacted_at: message.send_at,
      has_unread_messages: true,
      has_message_error: false,
      active: true
    )

    rr.user.update!(has_unread_messages: true)

    MessageRedactionJob.perform_later(message: message)

    MessageBroadcastJob.perform_later(message: message)

    message_alert = MessageAlertBuilder.build_alert(
      reporting_relationship: rr,
      reporting_relationship_path: Rails.application.routes.url_helpers.reporting_relationship_path(rr),
      clients_path: Rails.application.routes.url_helpers.clients_path
    )

    unless message_alert.nil?
      NotificationBroadcastJob.perform_later(
        channel_id: message.user.id,
        text: message_alert[:text],
        link_to: message_alert[:link_to],
        properties: { client_id: client.id }
      )
    end

    NotificationMailer.message_notification(message.user, message).deliver_later if message.user.message_notification_emails
  end
end
