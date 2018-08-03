module ApplicationHelper
  def phone_number_display(phone_number)
    # format the passed phone number for display
    return nil if phone_number.blank?
    PhoneNumberParser.format_for_display(phone_number)
  end

  def message_inbound_or_outbound(message)
    # return a string indicating whether the message is inbound or outbound
    return Message::INBOUND if message.inbound
    Message::OUTBOUND
  end

  def feature_flag_for(flag)
    @flags ||= {}
    @flags[flag] = FeatureFlag.enabled?(flag) if @flags[flag].nil?
    @flags[flag]
  end

  def client_messages_status(rr)
    if rr.has_message_error
      Message::ERROR
    elsif rr.has_unread_messages
      Message::UNREAD
    else
      Message::READ
    end
  end
end
