class Client < ApplicationRecord
  has_many :reporting_relationships, dependent: :nullify
  has_many :users, through: :reporting_relationships
  belongs_to :client_status
  has_many :messages, -> { order(send_at: :asc) }
  has_many :attachments, through: :messages

  scope :active, lambda {
    joins(:reporting_relationships)
      .where(reporting_relationships: { active: true })
  }

  accepts_nested_attributes_for :reporting_relationships

  before_validation :normalize_phone_number, if: :phone_number_changed?
  validate :service_accepts_phone_number, if: :phone_number_changed?

  validates_presence_of :last_name, :phone_number
  validates_uniqueness_of :phone_number

  def analytics_tracker_data
    {
      client_id: self.id,
      has_unread_messages: has_unread_messages,
      hours_since_contact: hours_since_contact,
      messages_all_count: messages.count,
      messages_received_count: inbound_messages_count,
      messages_sent_count: outbound_messages_count,
      messages_attachments_count: attachments.count,
      messages_scheduled_count: scheduled_messages_count,
      has_client_notes: notes.present?
    }
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def timestamp
    (last_contacted_at || created_at).to_time.to_i
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

  def hours_since_contact
    ((Time.now - (last_contacted_at || created_at)) / 3600).round
  end
end
