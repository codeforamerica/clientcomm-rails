class Client < ApplicationRecord
  belongs_to :user
  has_many :messages
  has_many :attachments, through: :messages

  validates :last_name, :presence => true
  validates :birth_date, :presence => true
  validates :phone_number, presence: true
  validates_uniqueness_of :phone_number, message: 'This phone number already belongs to a client in ClientComm. Need help? Chat with us by clicking the green chat button in the bottom-right of your screen.'

  def analytics_tracker_data
    {
      client_id: self.id,
      has_client_dob: !self.birth_date.nil?,
      has_unread_messages: (unread_messages_count > 0),
      hours_since_contact: hours_since_contact,
      messages_all_count: messages.count,
      messages_received_count: inbound_messages_count,
      messages_sent_count: outbound_messages_count,
      messages_attachments_count: attachments.count
    }
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def contacted_at
    # the date of the most recent message sent to or received from this client
    last_message = messages.order(:created_at).last
    if last_message
      return last_message.created_at
    end
    self.updated_at
  end

  def hours_since_contact
    ((Time.now - contacted_at) / 3600).round
  end

  def unread_messages_count
    # the number of messages received that are unread
    messages.unread.count
  end

  def inbound_messages_count
    # the number of messages received
    messages.inbound.count
  end

  def outbound_messages_count
    # the number of messages sent
    messages.outbound.count
  end

  def unread_messages_sort
    # return a 0 or 1 to sort clients with unread messages on
    [self.unread_messages_count, 1].min
  end

  # override default accessors
  def phone_number=(number_input)
    self[:phone_number] = PhoneNumberParser.normalize(number_input)
  end

end
