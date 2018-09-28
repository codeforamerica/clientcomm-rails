module ListMaker
  def self.transfer_users(user:)
    user.department.eligible_users.active.where.not(id: user.id).order(:full_name).pluck(:full_name, :id)
  end

  def self.merge_clients(user:, client:)
    user.clients.active.where.not(id: client.id).order(:first_name, :last_name)
        .map do |c|
      [
        "#{c.first_name.strip} #{c.last_name.strip}",
        c.id,
        { 'data-phone-number' => PhoneNumberParser.format_for_display(c.phone_number) }
      ]
    end
  end
end
