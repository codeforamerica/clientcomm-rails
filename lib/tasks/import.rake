require 'csv'
require 'open-uri'

namespace :import do
  task :slco_court_reminders, %i[court_dates_path court_locs_path dry_run] => :environment do |_, args|
    court_dates = CSV.parse(File.read(args.court_dates_path), headers: true)
    court_locs = CSV.parse(File.read(args.court_locs_path), headers: true)
    court_locs_hash = CourtRemindersImporter.generate_locations_hash(court_locs)

    CourtRemindersImporter.generate_reminders(court_dates, court_locs_hash, dry_run: args.dry_run.present?)
  end
end
