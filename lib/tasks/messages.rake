namespace :messages do
  task update_twilio_statuses: :environment do
    transient_messages = Message.where.not(inbound: true, twilio_status: %w[failed delivered undelivered blacklisted maybe_undelivered])
    Rails.logger.tagged('update twilio statuses') { Rails.logger.warn "updating #{transient_messages.count} transient messages" }

    transient_messages.each do |m|
      if m.send_at < Time.zone.now - 5.days
        Rails.logger.tagged('sms_status_update') { Rails.logger.warn "#{m.twilio_sid} - update_twilio_statuses ... maybe_undelivered" }
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
          Rails.logger.tagged('sms_status_update') { Rails.logger.warn "#{m.twilio_sid} - update_twilio_statuses ... #{twilio_status}" }
          m.update!(twilio_status: twilio_status)
          MessageRedactionJob.perform_later(message: m)
          MessageBroadcastJob.perform_later(message: m)
        end
      end
    end
  end

  task :create_test_relationships, %i[csv_path] => :environment do |_, args|
    messages = CSV.parse(File.read(args.csv_path), headers: true)

    messages.each do |message|
      cl = Client.find_by(phone_number: message['number_to'])
      unless cl
        FactoryBot.create :client, user: User.all.active.sample, phone_number: message['number_to']
      end
    end
  end

  task :import_from_twilio_csv, %i[csv_path] => :environment do |_, args|
    messages = CSV.parse(File.read(args.csv_path), headers: true)

    puts 'Importing Messages'
    messages.each do |message|
      message = message.to_h.with_indifferent_access
      client = Client.find_by(phone_number: message[:number_to])

      rrs = client.reporting_relationships.order(last_contacted_at: :desc)
      if rrs.empty?
        print '?'
        next
      end

      rr = rrs.first

      tm = TextMessage.find_or_initialize_by(twilio_sid: message[:twilio_sid]) do |msg|
        msg.twilio_sid = message[:twilio_sid]
        msg.twilio_status = message[:twilio_status]
        msg.number_to = message[:number_to]
        msg.number_from = rr.department.phone_number
        msg.reporting_relationship = rr
        msg.send_at = message[:send_at]
        msg.body = message[:body]
        msg.inbound = false
        msg.read = true
      end

      if tm.persisted?
        print '!'
      elsif !rr.active
        tm.save!
        print '-'
      else
        tm.save!
        print '#'
      end
    end

    puts ''
    puts 'Done Importing'
  end
end
