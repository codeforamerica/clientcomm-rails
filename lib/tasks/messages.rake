namespace :messages do
  task update_twilio_statuses: :environment do
    transient_messages = Message.where.not(inbound: true, twilio_status: %w[failed delivered undelivered blacklisted maybe_undelivered])
    Rails.logger.tagged('update twilio statuses') { Rails.logger.warn "updating #{transient_messages.count} transient messages" }

    transient_messages.each do |m|
      if m.send_at < Time.zone.now - 5.days
        m.update!(twilio_status: 'maybe_undelivered')
        MessageBroadcastJob.perform_later(message: m)
      else
        Rails.logger.tagged('update_twilio_statuses') { Rails.logger.warn "updating transient message #{m.id}" }
        begin
          twilio_status = SMSService.instance.status_lookup(message: m)
        rescue Twilio::REST::RestError => e
          raise e unless e.code == 20404
          CLOUD_WATCH.put_metric_data(
            namespace: ENV['DEPLOYMENT'],
            metric_data: [
              {
                metric_name: 'TwilioStatus404',
                timestamp: Time.zone.now,
                value: 1.0,
                unit: 'None',
                storage_resolution: 1
              }
            ]
          )
          Rails.logger.warn "404 getting message status from Twilio sid: #{m.twilio_sid}"
        else
          m.update!(twilio_status: twilio_status)
          MessageRedactionJob.perform_later(message: m)
          MessageBroadcastJob.perform_later(message: m)
        end
      end
    end
  end
end
