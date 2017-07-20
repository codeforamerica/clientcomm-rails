class ScheduledMessageBroadcastJob < ApplicationJob
  include ActionView::RecordIdentifier
  queue_as :default

  def perform(message:)
    channel = "scheduled_messages_#{message.client_id}"
    message_content = render_scheduled_message_partial(message)
    link_content = render_scheduled_message_link(message)
    message_dom_id = dom_id(message)
    ActionCable.server.broadcast(
      channel,
      message_html: content,
      message_dom_id: message_dom_id,
      message_id: message.id
    )
  end

  def render_scheduled_message_partial(message)
    MessagesController.render(
      partial: 'messages/message',
      locals: {message: message}
    )
  end

  def render_scheduled_message_link(count)
    MessagesController.render(
      partial: 'messages/scheduled_messages_link',
      locals: {count: count}
    )
  end
end
