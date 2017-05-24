module ApplicationHelper

  def phone_number_display(phone_number)
    PhoneNumberParser.format_for_display(phone_number)
  end

end
