class SortClients
  def self.run(user:)
    user.clients.where(active: true)
      .includes(:messages)
      .sort_by { |c| [c.unread_messages_sort, c.contacted_at] }
      .reverse
  end
end