class SortClients
  def self.run(user:)
    user.clients
      .where(active: true)
      .sort_by { |c|
        [c.has_unread_messages ? 1 : 0, (c.last_contacted_at || c.created_at) ]
      }.reverse
  end
end
