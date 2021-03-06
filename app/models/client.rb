class Client < ApplicationRecord
  has_many :reporting_relationships, dependent: :nullify
  has_many :users, through: :reporting_relationships
  has_many :messages, -> { order(send_at: :asc) }, through: :reporting_relationships
  has_many :attachments, through: :messages
  has_many :surveys, dependent: :nullify

  scope :active, lambda {
    joins(:reporting_relationships)
      .where(reporting_relationships: { active: true })
      .distinct
  }

  accepts_nested_attributes_for :surveys

  validates_associated :reporting_relationships
  accepts_nested_attributes_for :reporting_relationships

  before_validation :normalize_phone_number, if: :phone_number_changed?
  validate :service_accepts_phone_number, if: :phone_number_changed?

  validates :last_name, :phone_number, presence: true
  validates :phone_number, uniqueness: true
  validates :id_number, format: { with: /\A\d*\z/ }

  before_validation :normalize_next_court_date_at
  validate :next_court_date_at_is_a_date

  ransacker :stripped_phone_number, formatter: proc { |v| v.gsub(/\D/, '') } do |parent|
    parent.table[:phone_number]
  end

  def analytics_tracker_data
    {
      client_id: self.id,
      has_court_date: next_court_date_at.present?
    }
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_phone_number
    PhoneNumberParser.format_for_display(phone_number)
  end

  def timestamp(user:)
    (last_contacted_at(user: user) || relationship_started(user: user)).to_time.to_i
  end

  def inbound_messages_count
    # the number of messages received
    messages.inbound.count
  end

  def outbound_messages_count
    # the number of messages sent
    messages.outbound.count
  end

  def scheduled_messages_count
    messages.scheduled.count
  end

  def client_status(user:)
    reporting_relationships.find_by(user: user).client_status
  end

  def last_contacted_at(user:)
    reporting_relationships.find_by(user: user).last_contacted_at
  end

  def reporting_relationship(user:)
    reporting_relationships.find_by(user: user)
  end

  def relationship_started(user:)
    reporting_relationships.find_by(user: user).created_at
  end

  def notes(user:)
    reporting_relationships.find_by(user: user).notes
  end

  def active(user:)
    reporting_relationships.find_by(user: user).active
  end

  def active_users
    users.joins(:reporting_relationships).where(reporting_relationships: { active: true }).distinct
  end

  private

  def normalize_phone_number
    return unless self.phone_number

    self.phone_number = SMSService.instance.number_lookup(phone_number: self.phone_number)
  rescue SMSService::NumberNotFound
    @bad_number = true
  end

  def service_accepts_phone_number
    errors.add(:phone_number, :invalid) if @bad_number
  end

  def normalize_next_court_date_at
    bad_input = self.next_court_date_at.nil? && self.next_court_date_at_before_type_cast.class == String && !self.next_court_date_at_before_type_cast.empty?
    raw_input = self.next_court_date_at_before_type_cast.class == String && %r(\d{2}\/\d{2}\/\d{4}).match?(self.next_court_date_at_before_type_cast)
    return unless bad_input || raw_input

    self.next_court_date_at = Date.strptime(self.next_court_date_at_before_type_cast, '%m/%d/%Y')
  rescue ArgumentError
    @bad_next_court_date_at = true
  end

  def next_court_date_at_is_a_date
    errors.add(:next_court_date_at, :invalid) if @bad_next_court_date_at
  end
end
