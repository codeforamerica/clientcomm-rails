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
      client_id: message.client.id
    )
  end

  def broadcast(client_id:, count:)
    channel = "scheduled_messages_#{client_id}"
    link_content = render_scheduled_message_link(count)
    ActionCable.server.broadcast(channel, link_html: link_content)
  end

  def render_scheduled_message_link(count)
    MessagesController.render(
      partial: 'messages/scheduled_messages_link',
      locals: {count: count}
    )
  end
end
