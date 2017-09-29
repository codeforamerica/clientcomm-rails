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

  def client_messages_status(client)
    if client.has_message_error
      Message::ERROR
    elsif client.has_unread_messages
      Message::UNREAD
    else
      Message::READ
    end
  end
end
