module ListMaker
  def self.transfer_users(user:)
    user.department.eligible_users.active.where.not(id: user.id).order(:full_name).pluck(:full_name, :id)
  end

  def self.merge_clients(user:, client:)
    user.reporting_relationships.includes(:client).active.where.not(client_id: client.id).order('clients.first_name, clients.last_name')
        .map do |rr|
      [
        "#{rr.client.first_name&.strip} #{rr.client.last_name&.strip}",
        rr.client.id,
        { 'data-phone-number' => PhoneNumberParser.format_for_display(rr.client.phone_number),
          'data-timestamp' => rr.timestamp }
      ]
    end
  end
end
