class CreateCourtRemindersJob < ApplicationJob
  include ActionView::RecordIdentifier
  queue_as :default

  def perform(csv_file, _user)
    dates_content = Paperclip.io_adapters.for(csv_file.file).read
    court_dates = CSV.parse(dates_content, headers: true)
    locs_content = File.read(Rails.root.join('app', 'assets', 'config', 'court_locations.csv'))
    court_locs = CSV.parse(locs_content, headers: true)
    court_locs_hash = CourtRemindersImporter.generate_locations_hash(court_locs)
    begin
      CourtRemindersImporter.generate_reminders(court_dates, court_locs_hash)
    rescue StandardError
      CourtReminderMailer.failure(user).deliver_later
    else
      CourtReminderMailer.success(user).deliver_later
    end
  end
end
