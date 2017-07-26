class ScheduledMessageJob < ApplicationJob
  include ActionView::RecordIdentifier
  include ScheduledMessagesHelper

  queue_as :default

  def perform(message:, callback_url:)
    SMSService.instance.send_message(
        message: message,
        callback_url: callback_url
    )

    broadcast(
      count: scheduled_messages(user: message.user).count,
      client: message.client
    )
  end

  def broadcast(client:, count:)
    channel = "scheduled_messages_#{client.id}"
    link_content = render_scheduled_message_link(count: count, client: client)
    ActionCable.server.broadcast(channel, link_html: link_content, count: count)
  end

  def render_scheduled_message_link(count:, client:)
    MessagesController.render(
      partial: 'messages/scheduled_messages_link',
      locals: {count: count, client: client}
    )
  end
end
