Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.sleep_delay = 2
Delayed::Worker.max_attempts = 1
