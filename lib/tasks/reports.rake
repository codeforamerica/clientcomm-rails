namespace :reports do
  task :generate_and_send_reports => :environment do
    end_date = Time.zone.now
    if end_date.wday.to_s == ENV['REPORT_DAY']
      Department.all.each do |department|
        recipients = department.reports.pluck(:email)
        metrics = department.message_metrics(end_date)
        recipients.each do |recipient|
          NotificationMailer.report_usage(recipient, metrics, end_date.to_s)
                            .deliver_later
        end
      end
      Rails.logger.info 'Report task ran and sent reports'
    else
      Rails.logger.info 'Report task ran but sent no reports'
    end
  end
end
