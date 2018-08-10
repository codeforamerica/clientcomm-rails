class CloudWatchPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.around(:invoke_job) do |job, *args, &block|
      start_time = Time.zone.now
      handler = YAML.parse(job.handler).to_ruby
      job_class = handler.job_data['job_class']
      job_id = handler.job_data['job_id']
      Rails.logger.tagged("Job class: #{job_class} id: #{job_id}") do
        Rails.logger.info { 'BEGINS' }
        begin
          block.call(job, *args)
          # rubocop:disable Lint/RescueException
        rescue Exception => error
          Rails.logger.warn { 'ERRORED' }
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
          Rails.logger.warn { 'SUCCEEDED' }
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
        ensure
          time_delta = (Time.zone.now - start_time) * 1000
          Rails.logger.warn { "Job Ran in #{time_delta}ms" }
          CLOUD_WATCH.put_metric_data(
            namespace: ENV['DEPLOYMENT'],
            metric_data: [
              {
                metric_name: 'JobRunTime',
                timestamp: Time.zone.now,
                value: time_delta,
                unit: 'Milliseconds',
                storage_resolution: 1
              }
            ]
          )
        end
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
