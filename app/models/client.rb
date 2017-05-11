class Client < ApplicationRecord
  PHONE_NUMBER_REGEX = /\A\d{10}\z/

  validates :phone_number,
    format: { with: PHONE_NUMBER_REGEX, message: "Make sure the phone number is 10 digits." }
end
