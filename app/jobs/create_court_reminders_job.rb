class CreateCourtRemindersJob < ApplicationJob
  include ActionView::RecordIdentifier
  queue_as :default

  def perform(csv_file, user)
    dates_content = Paperclip.io_adapters.for(csv_file.file).read
    locs_content = File.read(Rails.root.join('app', 'assets', 'config', 'court_locations.csv'))
    court_locs = CSV.parse(locs_content, headers: true)
    court_locs_hash = CourtRemindersImporter.generate_locations_hash(court_locs)
    begin
      court_dates = CSV.parse(dates_content, headers: true)
      CourtRemindersImporter.generate_reminders(court_dates, court_locs_hash)
    rescue StandardError
      NotificationMailer.court_reminders_failure(user).deliver_later
    else
      NotificationMailer.court_reminders_success(user).deliver_later
    end
  end
end
