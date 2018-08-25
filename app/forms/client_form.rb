class ClientForm < Form
  attr_accessor :first_name, :last_name, :phone_number, :id_number,
                :next_court_date_at, :client_status_id, :notes

  attr_accessor :parsed_next_court_date_at

  attr_accessor :user, :client, :reporting_relationship

  validates :last_name, :phone_number, presence: true
  validates :id_number, format: { with: /\A\d*\z/ }

  before_validation :normalize_phone_number
  validate :service_accepts_phone_number

  before_validation :normalize_next_court_date_at
  validate :next_court_date_at_is_a_date

  def other_users
    []
    # @client.active_users.where.not(id: current_user.id)
  end

  def save
    return false unless valid?

    self.client = create_client
    self.reporting_relationship = create_reporting_relationship

    true
  end

  private

  def create_client
    Client.create!(
      first_name: first_name,
      last_name: last_name,
      phone_number: phone_number,
      id_number: id_number,
      next_court_date_at: next_court_date_at
    )
  end

  def create_reporting_relationship
    ReportingRelationship.create!(
      user: user,
      client: client,
      notes: notes,
      client_status_id: client_status_id
    )
  end

  def normalize_phone_number
    return unless phone_number

    self.phone_number = SMSService.instance.number_lookup(phone_number: phone_number)
  rescue SMSService::NumberNotFound
    @bad_number = true
  end

  def service_accepts_phone_number
    errors.add(:phone_number, :invalid) if @bad_number
  end

  def normalize_next_court_date_at
    correctly_formatted = %r(\d{2}\/\d{2}\/\d{4}).match?(next_court_date_at)
    return unless correctly_formatted || next_court_date_at.blank?

    self.parsed_next_court_date_at = Date.strptime(next_court_date_at, '%m/%d/%Y')
  rescue ArgumentError
    @bad_next_court_date_at = true
  end

  def next_court_date_at_is_a_date
    errors.add(:next_court_date_at, :invalid) if @bad_next_court_date_at
  end
end
