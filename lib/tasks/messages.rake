namespace :messages do
  task update_twilio_statuses: :environment do
    transient_messages = Message.where.not(inbound: true, twilio_status: %w[failed delivered undelivered])

    transient_messages.each do |m|
      twilio_status = SMSService.instance.status_lookup(message: m)
      begin
        m.update(twilio_status: twilio_status)
      rescue ActiveRecord::StaleObjectError
        Rails.logger.warn('StaleObjectError on update_twilio_statuses task')
        next
      end
      MessageRedactionJob.perform_later(message: m)
    end
  end
end
