namespace :reports do
  task :generate_and_send_reports => :environment do
    date = Time.now
    Department.all.each do |department|
      recipients = department.reports.pluck(:email)
      metrics = department.message_metrics(date)
      recipients.each { |recipient| NotificationMailer.report_usage(recipient, metrics, date).deliver }
    end
  end
end
