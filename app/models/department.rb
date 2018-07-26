class Department < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :reports, dependent: :destroy
  has_many :client_statuses, dependent: :destroy
  belongs_to :unclaimed_user, class_name: 'User', foreign_key: 'user_id', inverse_of: :department

  before_validation :normalize_phone_number, if: :phone_number_changed?
  validate :service_accepts_phone_number, if: :phone_number_changed?

  def eligible_users
    User.where(department: self).where.not(id: user_id)
  end

  def message_metrics(this_date)
    metrics = []
    users.active.order(:full_name).each do |user|
      all_messages = user.messages.messages.where('send_at < ?', this_date).where('send_at > ?', this_date - 7.days)
      metrics << [
        user.full_name,
        all_messages.outbound.count,
        all_messages.outbound.where("messages.send_at > messages.created_at + interval '15 minutes'").count,
        all_messages.inbound.count,
        all_messages.outbound.count + all_messages.inbound.count
      ]
    end
    metrics
  end

  def client_statuses?
    client_statuses.count.positive?
  end

  private

  def normalize_phone_number
    return unless phone_number

    self.phone_number = SMSService.instance.number_lookup(phone_number: phone_number)
  rescue SMSService::NumberNotFound
    @bad_number = true
  end

  def service_accepts_phone_number
    errors.add(:phone_number, :invalid) if @bad_number
  end
end
