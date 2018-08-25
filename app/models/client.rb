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

  validates :phone_number, uniqueness: true

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
end
