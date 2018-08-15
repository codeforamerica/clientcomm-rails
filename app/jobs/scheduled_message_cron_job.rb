class ScheduledMessageCronJob < ApplicationJob
  queue_as :high_priority

  def perform
    TextMessage.where(sent: false).where('send_at <= ?', Time.zone.now + 15.minutes).each(&:send_message)
  end
end
