class ScheduledMessageCronJob < ApplicationJob
  queue_as :high_priority

  def perform
    send_messages = TextMessage.where(sent: false).where(inbound: false).where('send_at < ?', Time.zone.now + APP_CONFIG['scheduled_message_rate'].minutes)
    send_count = send_messages.count
    send_messages.find_each(&:send_message)
    CLOUD_WATCH.put_metric_data(
      namespace: ENV['DEPLOYMENT'],
      metric_data: [
        {
          metric_name: 'MessagesScheduled',
          timestamp: Time.zone.now,
          value: send_count,
          unit: 'None',
          storage_resolution: 1
        }
      ]
    )
  end
end
