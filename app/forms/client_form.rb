class ClientForm < Form
  attr_accessor :first_name, :last_name, :phone_number, :id_number,
                :next_court_date_at, :client_status_id, :notes

  def save; end

  def other_users
    []
    # @client.active_users.where.not(id: current_user.id)
  end

  private

  def persist!; end
end
