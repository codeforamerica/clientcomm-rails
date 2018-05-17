class MessageBroadcastJob < ApplicationJob
  include ActionView::RecordIdentifier
  queue_as :default

  def perform(message:)
    channel = "messages_#{message.user.id}_#{message.client.id}"
    content = render_message_partial(message)
    message_dom_id = "message_#{message.id}"
    ActionCable.server.broadcast(
      channel,
      message_html: content,
      message_dom_id: message_dom_id,
      message_id: message.id
    )
    ActionCable.server.broadcast("clients_#{message.user.id}", {})
  end

  def render_message_partial(message)
    MessagesController.render(
      partial: 'messages/message',
      locals: { message: message }
    )
  end
end
