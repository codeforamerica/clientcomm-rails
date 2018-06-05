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
      total_rrs = CourtRemindersImporter.generate_reminders(court_dates, court_locs_hash)
    rescue StandardError
      NotificationMailer.court_reminders_failure(user).deliver_later
      AnalyticsService.track(
        label: 'court_reminder_upload_failure',
        distinct_id: distinct_id(user.id),
        data: {
          admin_id: user.id
        }
      )
    else
      NotificationMailer.court_reminders_success(user).deliver_later
      AnalyticsService.track(
        label: 'court_reminder_upload_success',
        distinct_id: distinct_id(user.id),
        data: {
          admin_id: user.id,
          messages_scheduled: CourtReminder.scheduled.count,
          clients_matched: total_rrs
        }
      )
    end
  end

  private

  def distinct_id(user_id)
    "#{URI.parse(ENV['DEPLOY_BASE_URL']).hostname.split('.')[0..1].join('_')}-admin_#{user_id}"
  end
end
