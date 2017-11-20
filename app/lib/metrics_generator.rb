class MetricsGenerator
  def self.generate
    %Q(
Case managers: #{User.count}
Active Clients: #{Client.distinct.joins(:reporting_relationships).where(reporting_relationships: { active: true }).count}
Total Clients: #{Client.count}
New conversations in last week: #{new_conversations}
Average number of messages per conversation: #{average_messages_in_conversation}
Total number of messages sent/received: #{Message.count}
Total number of messages received: #{received_messages}
Total number of messages sent: #{sent_messages}
    )
  end

  class << self
    private

    def sent_messages
      Message.where(inbound: false).count
    end

    def received_messages
      Message.where(inbound: true).count
    end

    def clients_with_messages
      Message.distinct.pluck(:client_id)
    end

    def average_messages_in_conversation
      return 0 if Message.count == 0

      Message.count / clients_with_messages.size
    end

    def new_conversations
      clients_with_messages.map do |client|
        Client.find(client).messages.sort_by(&:created_at).first.created_at
      end.select do |time|
        time > Time.now.last_week
      end.count
    end
  end
end
