class Client < ApplicationRecord
  belongs_to :user
  has_many :messages

  def full_name
    "#{first_name} #{last_name}"
  end

  def contacted_at
    # the date of the most recent message sent to or received from this client
    last_message = Message.where(client: self).order(:created_at).last
    if last_message
      return last_message.created_at
    end
    self.updated_at
  end

  def received_message_at
    # the date of the most recent message received from this client
    last_received_message = Message
      .where(client: self, inbound: true)
      .order(:created_at)
      .last

    if last_received_message
      return last_received_message.created_at
    end
    self.updated_at
  end

  def unread_message_count
    # the number of messages received that are unread
    Message.where(read: false, client: self).count
  end

  # override default accessors
  def phone_number=(number_input)
    self[:phone_number] = PhoneNumberParser.normalize(number_input)
  end

end
