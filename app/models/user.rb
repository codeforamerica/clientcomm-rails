class User < ApplicationRecord
  has_many :clients, dependent: :destroy
  has_many :messages
  has_many :templates

  before_validation :normalize_desk_phone_number, if: :desk_phone_number_changed?
  validate :service_accepts_desk_phone_number, if: :desk_phone_number_changed?

  validates_presence_of :full_name
  validates_uniqueness_of :desk_phone_number

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

  def clients_count
    # the number of associated clients
    clients.count
  end

  def active_for_authentication?
    super && active
  end

  def inactive_message
    'Sorry, this account has been disabled. Please contact an administrator.'
  end

  private

  def normalize_desk_phone_number
    return unless self.desk_phone_number

    self.desk_phone_number = SMSService.instance.number_lookup(phone_number: self.desk_phone_number)
  rescue SMSService::NumberNotFound
    @bad_number = true
  end

  def service_accepts_desk_phone_number
    errors.add(:desk_phone_number, :invalid) if @bad_number
  end
end
