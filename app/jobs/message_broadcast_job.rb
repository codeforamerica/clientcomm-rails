class MessageBroadcastJob < ApplicationJob
  include ActionView::RecordIdentifier
  queue_as :default

  def perform(message:)
    channel = "messages_#{message.user.id}_#{message.client.id}"
    message_html = render_message_partial(message)
    status_html = render_message_status_partial(message)
    message_dom_id = "message_#{message.id}"
    ActionCable.server.broadcast(
      channel,
      message_html: message_html,
      message_status_html: status_html,
      message_status: message.twilio_status,
      message_dom_id: message_dom_id,
      message_id: message.id
    )
    ActionCable.server.broadcast("clients_#{message.user.id}", {})
    message_json = message.as_json(include: { reporting_relationship: { include: :client } })
    ActionCable.server.broadcast("events_#{message.user.id}", type: 'message', data: message_json)
  end

  def render_message_partial(message)
    MessagesController.render(
      partial: "#{message.class.to_s.tableize}/#{message.class.to_s.tableize.singularize}",
      locals: { "#{message.class.to_s.tableize.singularize}": message }
    )
  end

  def render_message_status_partial(message)
    return nil unless message.class.to_s == 'TextMessage'
    MessagesController.render(
      partial: 'text_messages/text_message_status', locals: { text_message: message }
    )
  end
end
