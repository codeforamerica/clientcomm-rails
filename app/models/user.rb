class User < ApplicationRecord
  has_many :reporting_relationships
  has_many :clients, through: :reporting_relationships
  has_many :messages, through: :reporting_relationships
  has_many :templates
  belongs_to :department

  scope :active, -> { where(active: true) }

  scope :active_rr, lambda {
    joins(:reporting_relationships)
      .where(reporting_relationships: { active: true })
      .distinct
  }

  before_validation :normalize_phone_number, if: :phone_number_changed?
  validate :service_accepts_phone_number, if: :phone_number_changed?
  validate :no_active_reporting_relationships_if_inactive
  validates_associated :reporting_relationships, on: :update, message: I18n.t('activerecord.errors.models.user.attributes.reporting_relationships.invalid')

  validates_presence_of :full_name

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def analytics_tracker_data
    {
      clients_count: clients_count,
      has_unread_messages: unread_messages_count > 0,
      unread_messages_count: unread_messages_count
    }
  end

  def unread_messages_count
    # the number of messages received that are unread
    messages.unread.count
  end

  delegate :count, to: :clients, prefix: true

  def active_for_authentication?
    super && active
  end

  def inactive_message
    'Sorry, this account has been disabled. Please contact an administrator.'
  end

  private

  def no_active_reporting_relationships_if_inactive
    errors.add(:active, :active_reporting_relationships) if active == false && reporting_relationships.where(active: true).any?
  end

  def normalize_phone_number
    return unless self.phone_number

    self.phone_number = SMSService.instance.number_lookup(phone_number: self.phone_number)
  rescue SMSService::NumberNotFound
    @bad_number = true
  end

  def service_accepts_phone_number
    errors.add(:phone_number, :invalid) if @bad_number
  end
end

# client does not exist
# client exists for this user
# client exists for another user in this dept
# client exists for another user in another department
