require 'csv'

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
    end
  end

  task :long_messages => :environment do
    io = $stdout.dup
    CSV(io) do |csv|
      csv << %w[name email client id length timestamp]
      Message.messages.where('length(body) > 1600').find_each do |msg|
        csv << [msg.user.full_name, msg.user.email, msg.client.full_name, msg.id, msg.body.length, msg.created_at]
      end
    end
  end
end
