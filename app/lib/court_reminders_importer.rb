module CourtRemindersImporter
  def self.generate_reminders(court_dates, court_locations, options = {})
    time_zone_offset = '-0600' # Make sure this is by instance eventually
    total_rrs = 0
    Message.transaction do
      Rails.logger.tagged('court reminders') do
        Rails.logger.info { 'Begin court reminders import' }
        Rails.logger.info { "Deleting #{Message.scheduled.auto_court_reminders.count} existing court reminders" }
        Message.scheduled.auto_court_reminders.destroy_all unless options[:dry_run]
        court_dates.each do |court_date|
          Rails.logger.info { "Creating reminder for ctrack #{court_date['ofndr_num']}" }
          next if court_date['ofndr_num'].nil?
          matching_rrs = ReportingRelationship.where(notes: court_date['ofndr_num'], active: true)
          Rails.logger.info { "Found #{matching_rrs.count} RRs with IDs #{matching_rrs.pluck(:id)} with the same ctrack" }

          rr = matching_rrs.left_joins(:messages).order('messages.send_at DESC NULLS LAST').first
          next if rr.nil?
          matching_rrs_count = matching_rrs.count
          total_rrs += matching_rrs_count
          Rails.logger.tagged("client: #{rr.client.id}") do
            court_date_at = Time.strptime("#{court_date['crt_dt']} #{court_date['crt_tm']} #{time_zone_offset}", '%m/%d/%Y %H:%M %z')
            next if court_date_at < Time.zone.now

            body = I18n.t(
              'message.auto_court_reminder',
              location: court_locations[court_date['(expression)']],
              date: court_date_at.strftime('%-m/%-d/%Y'),
              time: court_date_at.strftime('%-l:%M%P'),
              room: court_date['crt_rm']
            )
            send_at = court_date_at.utc - 1.day

            Rails.logger.info { "Body: \"#{body}\"" }
            Rails.logger.info { "Send At: \"#{send_at}\"" }

            message = CourtReminder.new(
              body: body,
              reporting_relationship: rr,
              number_from: rr.user.department.phone_number,
              number_to: rr.client.phone_number,
              send_at: send_at,
              read: true
            )

            unless options[:dry_run]
              message.save!
              message.send_message
            end
          end
        end
      end
    end
    total_rrs
  end

  def self.generate_locations_hash(court_locations)
    court_locs_hash = {}

    court_locations.each do |loc|
      court_locs_hash[loc['crt_loc_cd']] = loc['crt_loc_desc']
    end

    court_locs_hash
  end
end
