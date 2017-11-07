class NotificationBroadcastJob < ApplicationJob
  queue_as :default

  def perform(channel_id:, text:, link_to:, properties:)
    channel = "notifications_#{channel_id}"
    content = render_notification_partial(text, link_to)
    ActionCable.server.broadcast(
      channel,
      properties: properties,
      notification_html: content
    )
  end

  def render_notification_partial(text, link_to)
    ClientsController.render(
      partial: 'layouts/flash',
      locals: { classes: ['flash'], body: text, link_to: link_to }
    )
  end
end
