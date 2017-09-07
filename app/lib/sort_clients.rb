class SortClients
  def self.run(user:)
    user.clients.where(active: true).order(has_unread_messages: :desc, last_contacted_at: :desc)
  end
end