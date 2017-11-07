class SortClients
  def self.clients_list(user:)
    user.clients
        .where(active: true)
        .sort_by { |c|
          [c.has_unread_messages ? 1 : 0, (c.last_contacted_at || c.created_at)]
        }.reverse
  end

  def self.mass_messages_list(user:, selected_clients: [])
    user.clients
        .where(active: true)
        .sort_by { |c|
          [selected_clients.include?(c.id) ? 1 : 0, (c.last_contacted_at || c.created_at)]
        }.reverse
  end
end
