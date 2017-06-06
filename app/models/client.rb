class Client < ApplicationRecord
  belongs_to :user
  has_many :messages

  def full_name
    "#{first_name} #{last_name}"
  end

  def contacted_at
    # the date of the most recent message sent or received
    last_message = Message.where(client: self).order(:created_at).last
    if last_message
      return last_message.created_at
    end
    self.updated_at
  end

  # override default accessors
  def phone_number=(number_input)
    self[:phone_number] = PhoneNumberParser.normalize(number_input)
  end

end
