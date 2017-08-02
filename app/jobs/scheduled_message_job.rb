class ScheduledMessageJob < ApplicationJob
  include ActionView::RecordIdentifier
  include ScheduledMessagesHelper

  queue_as :default

  def perform(message:, send_at:, callback_url:)
    return if message.sent
    return unless message.send_at.to_i == send_at

    # Locking to prevent race conditions between jobs
    begin
      message.update(sent: true)
    rescue ActiveRecord::StaleObjectError
      return
    end

    SMSService.instance.send_message(
        message: message,
        callback_url: callback_url
    )

    broadcast(
      count: scheduled_messages(client: message.client).count,
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
