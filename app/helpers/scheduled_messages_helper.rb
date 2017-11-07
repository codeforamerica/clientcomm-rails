module ScheduledMessagesHelper
  def scheduled_messages(client:)
    client.messages
          .where('send_at >= ?', Time.now)
          .order('created_at ASC')
  end
end
