module CourtRemindersImporter
  def self.generate_reminders(court_dates, court_locations, options = {})
    time_zone_offset = '-0600' # Make sure this is by instance eventually

    Message.transaction do
      Message.scheduled.auto_court_reminders.destroy_all unless options[:dry_run]
      court_dates.each do |court_date|
        matching_rrs = ReportingRelationship.where(notes: court_date['ofndr_num'], active: true)
        Rails.logger.info { "[importing court reminders] Found #{matching_rrs.count} RRs with IDs #{matching_rrs.pluck(:id)} with the same ctrack" }

        rr = matching_rrs.left_joins(:messages).order('messages.send_at DESC NULLS LAST').first
        next if rr.nil?

        Rails.logger.tagged("Reminder for Client: #{rr.client.id}") do
          court_date_at = Time.strptime("#{court_date['crt_dt']} #{court_date['crt_tm']} #{time_zone_offset}", '%m/%d/%Y %H:%M %z')
          next if court_date_at < Time.zone.now

          body = I18n.t(
            'message.auto_court_reminder',
            location: court_locations[court_date['(expression)']],
            date: court_date_at.strftime('%-m/%-d/%Y'),
            time: court_date_at.strftime('%-l:%M%P'),
            room: court_date['crt_rm']
          )

          Rails.logger.info { "Body: \"#{body}\"" }

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

          unless options[:dry_run]
            message.save!
            message.send_message
          end
        end
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
