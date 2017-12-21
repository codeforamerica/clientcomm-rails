class Department < ApplicationRecord
  has_many :users, dependent: :nullify, inverse_of: :department
  belongs_to :unclaimed_user, class_name: 'User', foreign_key: 'user_id', inverse_of: :department

  before_validation :normalize_phone_number, if: :phone_number_changed?
  validate :service_accepts_phone_number, if: :phone_number_changed?

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
