class NotificationBroadcastJob < ApplicationJob
  queue_as :default

  def perform(text:, link_to:, client:)
    channel = "notifications_#{client.user_id}"
    content = render_notification_partial(text, link_to)
    ActionCable.server.broadcast(
      channel,
      client_id: client.id,
      notification_html: content
    )
  end

  def render_notification_partial(text, link_to)
    ClientsController.render(
      partial: 'layouts/flash',
      locals: {classes: ['flash'], body: text, link_to: link_to}
    )
  end
end
