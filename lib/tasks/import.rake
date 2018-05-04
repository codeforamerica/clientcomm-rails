require 'csv'
require 'open-uri'

namespace :import do
  task :slco_court_reminders, %i[court_dates_file_path dryrun] => :environment do |_, args|
    args.with_defaults(dryrun: true)
    abort 'Please pass the path for the court dates file' if args.court_dates_file_path.nil?
    time_zone_offset = '-0600'

    court_locations_uri = 'https://raw.githubusercontent.com/slco-2016/cTracksImporter/master/court_locations.csv'
    court_locations_raw = open(court_locations_uri)
    court_locations = decorate_court_locations(CSV.parse(court_locations_raw, headers: true))

    court_dates_raw = File.read(args.court_dates_file_path)
    court_dates = CSV.parse(court_dates_raw, headers: true)

    Rails.logger.info { "Starting processing of #{court_dates.count} court dates." }

    court_dates.each do |court_date|
      Rails.logger.info { "Processing #{court_date['ofndr_num']}" }
      rr = ReportingRelationship.find_by(notes: court_date['ofndr_num'], active: true)
      next if rr.nil?

      court_date_at = Time.strptime("#{court_date['crt_dt']} #{court_date['crt_tm']} #{time_zone_offset}", '%m/%d/%Y %H:%M %z')
      time_show = court_date_at.strftime('%-l:%M %p')
      body = "Automated alert: Your next court date is at #{court_locations[court_date['(expression)']]} "\
        "on #{court_date['crt_dt']}, #{time_show} in Rm #{court_date['crt_rm']}. Please text with any questions."

      send_at = court_date_at.utc - 1.day

      found_dupe = false
      rr.messages.scheduled.each do |existing_message|
        if ((send_at - existing_message.send_at) * 24 * 60).to_i.abs < 1 && body == existing_message.body
          Rails.logger.warn { "Found existing duplicate message #{existing_message.id} for client #{rr.client_id}; skipping." }
          found_dupe = true
        end
      end

      next if found_dupe

      if args.dryrun == 'false'
        feedback = "CREATING: ctrack_id: #{court_date['ofndr_num']}, client: #{rr.client.id}, user: #{rr.user.id}, send_at: #{send_at} body: #{body}"
        Rails.logger.info { feedback }
      else
        feedback = "DRYRUN: ctrack_id: #{court_date['ofndr_num']}, client: #{rr.client.id}, user: #{rr.user.id}, send_at: #{send_at} body: #{body}"
        Rails.logger.info { feedback }
        next
      end

      message = Message.new(
        body: body,
        reporting_relationship: rr,
        number_from: rr.user.department.phone_number,
        number_to: rr.client.phone_number,
        send_at: send_at,
        read: true
      )

      if message.invalid? || message.past_message?
        feedback = "** INVALID: ctrack_id: #{court_date['ofndr_num']}, client: #{rr.client.id}, user: #{rr.user.id}, send_at: #{send_at}"
        Rails.logger.warn { feedback }
        next
      end

      message.save!
      message.send_message
    end
  end

  def decorate_court_locations(locations_csv)
    decorated_locations = {}
    locations_csv.each do |row|
      name = row['crt_loc_desc'].titleize

      case name
      when 'Salt Lake District'
        name += ' (Matheson Courthouse 450 South State St)'
      when 'Salt Lake City Justice'
        name += ' (333 S 200 E)'
      when 'Salt Lake County Justice'
        name += ' (2100 South State St)'
      when 'South Jordan Justice'
        name += ' (1600 West Towne Center Drive)'
      when 'West Valley Justice'
        name += ' (3590 S 2700 W)'
      when 'Midvale Justice'
        name += ' (7505 S Holden St)'
      when 'West Jordan Justice'
        name += ' (8040 South Redwood Road)'
      when 'Layton District'
        name += ' (425 N. Wasatch)'
      end

      decorated_locations[row['crt_loc_cd']] = name
    end
    decorated_locations
  end
end
