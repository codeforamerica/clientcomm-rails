class SortClients
  def self.clients_list(user:)
    user.reporting_relationships
        .eager_load(:client)
        .active
        .order('has_unread_messages DESC, COALESCE(reporting_relationships.last_contacted_at, reporting_relationships.created_at) DESC')
  end

  def self.mass_messages_list(user:, selected_clients: [])
    user.clients
        .active
        .sort_by do |c|
          [selected_clients.include?(c.id) ? 1 : 0, (c.last_contacted_at(user: user) || c.relationship_started(user: user))]
        end.reverse
  end
end
