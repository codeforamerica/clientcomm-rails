module DatetimeHelper
  def date_or_false(scheduled_message)

    # TODO
      # - Check if all date params are present
      # - Return error object if date in past
    send_date = DateTime.new(scheduled_message["send_date(1i)"].to_i,
                              scheduled_message["send_date(2i)"].to_i,
                              scheduled_message["send_date(3i)"].to_i,
                              scheduled_message["send_date(4i)"].to_i,
                              scheduled_message["send_date(5i)"].to_i)

    send_date
  end
end
