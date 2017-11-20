class Department < ApplicationRecord
  has_many :users

  before_validation :normalize_phone_number, if: :phone_number_changed?
  validate :service_accepts_phone_number, if: :phone_number_changed?

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
end
