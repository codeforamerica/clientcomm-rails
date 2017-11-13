module PhoneNumberParser
  # NOTE: assumes US numbers

  def self.make_bare(phone_number)
    # return the phone number without country code or non-numeric characters
    stripped = phone_number.to_s.gsub(/\D+/, '')
    stripped[[-10, -1 * stripped.length].max..-1]
  end

  def self.format_for_display(phone_number)
    # format for display, like: "(243) 555-1212"
    bare = self.make_bare(phone_number)
    "(#{bare[0..2]}) #{bare[3..5]}-#{bare[6..-1]}"
  end
end
