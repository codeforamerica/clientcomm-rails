class ScheduledMessageJob < ApplicationJob
  include ActionView::RecordIdentifier

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

    message.reporting_relationship.update!(last_contacted_at: message.send_at)

    SMSService.instance.send_message(
      message: message,
      callback_url: callback_url
    )

    if message.user == message.user.department.unclaimed_user && ((message.send_at - message.created_at) > 30.minutes)
      Rails.logger.warn { "Unclaimed user id: #{message.user.id} sent message id: #{message.id}" }
    end

    broadcast(
      message: message,
      count: message.reporting_relationship.messages.scheduled.count
    )
  end

  def broadcast(message:, count:)
    channel = "scheduled_messages_#{message.user.id}_#{message.client.id}"
    rr = message.reporting_relationship
    link_content = render_scheduled_message_link(count: count, rr: rr)
    ActionCable.server.broadcast(channel, link_html: link_content, count: count)
  end

  def render_scheduled_message_link(count:, rr:)
    MessagesController.render(
      partial: 'reporting_relationships/scheduled_messages_link',
      locals: { count: count, rr: rr }
    )
  end
end
