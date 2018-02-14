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
      logger.warn('Invalid scheduled message conflict')
      return
    end

    ReportingRelationship.find_by(client: message.client, user: message.user).update!(last_contacted_at: message.send_at)

    SMSService.instance.send_message(
      message: message,
      callback_url: callback_url
    )

    broadcast(
      message: message,
      count: scheduled_messages(client: message.client).count
    )
  end

  def broadcast(message:, count:)
    channel = "scheduled_messages_#{message.user.id}_#{message.client.id}"
    rr = message.client.reporting_relationship(user: message.user)
    link_content = render_scheduled_message_link(count: count, rr: rr)
    ActionCable.server.broadcast(channel, link_html: link_content, count: count)
  end

  def render_scheduled_message_link(count:, rr:)
    MessagesController.render(
      partial: 'messages/scheduled_messages_link',
      locals: { count: count, rr: rr }
    )
  end
end
