class ScheduledMessageJob < ApplicationJob
  include ActionView::RecordIdentifier

  retry_on Twilio::REST::TwilioError

  queue_as :high_priority
  def perform(message:, callback_url:)
    message.reporting_relationship.update!(last_contacted_at: message.send_at)

    begin
      message_info = SMSService.instance.send_message(
        to: message.client.phone_number,
        from: message.number_from,
        body: message.body,
        callback_url: callback_url
      )
    rescue Twilio::REST::RestError => e
      raise e unless e.code == 21610
      message_info = MessageInfo.new(nil, 'blacklisted')
    end

    message.update!(
      twilio_sid: message_info.sid,
      twilio_status: message_info.status
    )

    MessageBroadcastJob.perform_now(message: message)
    MessageRedactionJob.perform_later(message: message) unless message_info.sid.nil?

    if message.user == message.user.department.unclaimed_user && ((message.send_at - message.created_at) > 30.minutes)
      Rails.logger.warn "Unclaimed user id: #{message.user.id} sent message id: #{message.id}"
    end

    broadcast(
      message: message,
      count: message.reporting_relationship.messages.scheduled.count
    )
  end
  # rubocop:enable Metrics/PerceivedComplexity

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
