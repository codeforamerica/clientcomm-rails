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

      rrs = client.reporting_relationships.active
      next if rrs.empty?
      raise 'Uh Oh' if rrs.count > 1

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
      else
        tm.save!
        print '#'
      end
    end

    puts ''
    puts 'Done Importing'
  end
end
