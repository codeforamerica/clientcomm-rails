class PhoneNumberParser
  # NOTE: assumes US numbers

  def self.normalize(phone_number)
    # add the US country code if necessary
    stripped = phone_number.to_s.gsub(/\D+/, "")
    if (stripped.length == 11) && (stripped[0] == '1')
      "+" + stripped
    elsif (stripped.length == 10)
      "+1" + stripped
    end
  end

  def self.format_for_display(phone_number)
    # format for display, like: "(243) 555-1212"
    stripped = phone_number.to_s.gsub(/\D+/, "")
    if (stripped.length == 11) && (stripped[0] == '1')
      stripped = stripped[1..-1]
    end
    "(#{stripped[0..2]}) #{stripped[3..5]}-#{stripped[6..-1]}"
  end
end
