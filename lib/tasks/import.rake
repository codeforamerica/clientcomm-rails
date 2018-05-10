require 'csv'
require 'open-uri'

namespace :import do
  task :slco_court_reminders, %i[court_dates_path court_locs_path] => :environment do |_, args|
    court_dates = CSV.parse(File.read(args.court_dates_path), headers: true)
    court_locs = CSV.parse(File.read(args.court_locs_path), headers: true)
    court_locs_hash = CourtRemindersImporter.generate_locations_hash(court_locs)

    CourtRemindersImporter.generate_reminders(court_dates, court_locs_hash)
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
