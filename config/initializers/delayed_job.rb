Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.sleep_delay = 2
Delayed::Worker.max_attempts = 1
Delayed::Worker.queue_attributes = {
  high_priority: { priority: -10 },
  low_priority: { priority: 10 }
}
