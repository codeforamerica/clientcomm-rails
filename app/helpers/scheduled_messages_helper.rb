module ScheduledMessagesHelper
  def scheduled_messages(user:)
    user.messages.where('send_at > ?', Time.now)
  end
end
