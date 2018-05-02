namespace :messages do
  task update_twilio_statuses: :environment do
    transient_messages = Message.where.not(inbound: true, twilio_status: %w[failed delivered undelivered])

    transient_messages.each do |m|
      twilio_status = SMSService.instance.status_lookup(message: m)
      m.update(twilio_status: twilio_status)
      MessageRedactionJob.perform_later(message: m)
    end
  end
end
