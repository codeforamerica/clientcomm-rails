namespace :delayed_cron_job do
  task reset: :environment do
    Delayed::Job.where.not(cron: nil).destroy_all
    DeadManSwitchJob.perform_later
    ScheduledMessageCronJob.set(cron: '*/15 * * * *').perform_later
    DeadManSwitchJob.set(cron: '* * * * *').perform_later
  end
end
