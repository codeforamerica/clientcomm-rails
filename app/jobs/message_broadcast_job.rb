class MessageBroadcastJob < ApplicationJob
  queue_as :default

  def perform(message, dom_id)
    channel = "messages_#{message.client_id}"
    content = render_message_partial(message)
    ActionCable.server.broadcast channel, message_html: content, message_dom_id: dom_id
  end

  def render_message_partial(message)
    MessagesController.render(
      partial: 'messages/message',
      locals: {message: message}
    )
  end
end
