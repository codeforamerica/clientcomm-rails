module ApplicationHelper

  def phone_number_display(phone_number)
    # format the passed phone number for display
    PhoneNumberParser.format_for_display(phone_number)
  end

  def message_inbound_or_outbound(message)
    # return a string indicating whether the message is inbound or outbound
    return Message::INBOUND if message.inbound
    Message::OUTBOUND
  end

  def client_messages_read_or_unread(client)
    # return a string indicating whether the client has read or unread messages
    client.unread_messages_count == 0 ? Message::READ : Message::UNREAD
  end
end
