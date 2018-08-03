class CloudWatchPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.around(:invoke_job) do |job, *args, &block|
      begin
        block.call(job, *args)
      # rubocop:disable Lint/RescueException
      rescue Exception => error
        CLOUD_WATCH.put_metric_data(
          namespace: ENV['DEPLOYMENT'],
          metric_data: [
            {
              metric_name: 'JobRaisedError',
              timestamp: Time.zone.now,
              value: 1.0,
              unit: 'None',
              storage_resolution: 1
            }
          ]
        )
        raise error
      else
        CLOUD_WATCH.put_metric_data(
          namespace: ENV['DEPLOYMENT'],
          metric_data: [
            {
              metric_name: 'JobSucceeded',
              timestamp: Time.zone.now,
              value: 1.0,
              unit: 'None',
              storage_resolution: 1
            }
          ]
        )
      end
    end
  end
end
Delayed::Worker.plugins << CloudWatchPlugin
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.sleep_delay = 2
Delayed::Worker.max_attempts = 1
Delayed::Worker.queue_attributes = {
  high_priority: { priority: -10 },
  low_priority: { priority: 10 },
  dead_man_switch: { priority: 20 }
}
