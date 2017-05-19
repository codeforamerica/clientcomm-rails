class Client < ApplicationRecord
  belongs_to :user
  has_many :messages

  PHONE_NUMBER_REGEX = /\A\d{10}\z/

  validates :phone_number,
    format: { with: PHONE_NUMBER_REGEX, message: "Make sure the phone number is 10 digits." }

  def full_name
    "#{first_name} #{last_name}"
  end

end
