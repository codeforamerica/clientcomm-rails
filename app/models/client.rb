class Client < ApplicationRecord
  belongs_to :user
  has_many :messages

  def full_name
    "#{first_name} #{last_name}"
  end

  def phone_number_display
    PhoneNumberParser.format_for_display(phone_number)
  end

end
