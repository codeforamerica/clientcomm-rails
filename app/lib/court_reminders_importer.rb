module CourtRemindersImporter
  def self.generate_reminders(court_dates, court_locations)
    time_zone_offset = '-0600' # Make sure this is by instance eventually

    Message.transaction do
      Message.scheduled.auto_court_reminders.destroy_all
      court_dates.each do |court_date|
        rr = ReportingRelationship.where(notes: court_date['ofndr_num'], active: true).order('last_contacted_at DESC').first
        next if rr.nil?

        court_date_at = Time.strptime("#{court_date['crt_dt']} #{court_date['crt_tm']} #{time_zone_offset}", '%m/%d/%Y %H:%M %z')
        body = I18n.t(
          'messages.auto_court_reminder',
          location: court_locations[court_date['(expression)']],
          date: court_date_at.strftime('%m/%d/%Y'),
          time: court_date_at.strftime('%l:%M%P'),
          room: '2'
        )

        send_at = court_date_at.utc - 1.day

        message = Message.new(
          body: body,
          reporting_relationship: rr,
          number_from: rr.user.department.phone_number,
          number_to: rr.client.phone_number,
          send_at: send_at,
          read: true,
          marker_type: Message::AUTO_COURT_REMINDER
        )

        message.save!
      end
    end
  end

  def self.generate_locations_hash(court_locations)
    court_locs_hash = {}

    court_locations.each do |loc|
      court_locs_hash[loc['crt_loc_cd']] = loc['crt_loc_desc']
    end

    court_locs_hash
  end
end
