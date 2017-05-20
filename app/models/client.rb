class Client < ApplicationRecord
  belongs_to :user
  has_many :messages

  PHONE_NUMBER_REGEX = /\A\d{10}\z/

  validates :phone_number,
    format: { with: PHONE_NUMBER_REGEX, message: "Make sure the phone number is 10 digits." }

  def full_name
    "#{first_name} #{last_name}"
  end

  def phone_number_display
    stripped = phone_number.to_s.gsub(/\D+/, "")
    if (stripped.length == 11) && (stripped[0] == '1')
      stripped = stripped[1..-1]
    end
    "(#{stripped[0..2]}) #{stripped[3..5]}-#{stripped[6..-1]}"
  end

end
