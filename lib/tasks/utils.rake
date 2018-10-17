namespace :utils do
  #
  # run the tasks below remotely
  #

  task get_status: :environment do |_, args|
    # usage: heroku run rake utils:get_status[twilio_sid_01,twilio_sid_02,...] -a clientcom-xxx
    #   args:
    #         twilio_sid_xx: Twilio SIDs

    if args.extras.empty?
      puts 'no Twilio SIDs passed; usage: heroku run rake utils:get_status[SM1a...,SM1b...,...]'
      next
    end

    twilio_sids = args.extras

    start_message = "getting statuses for #{twilio_sids.count} Twilio SIDs"
    puts start_message
    puts '=' * start_message.length

    sids_not_found = []

    twilio_sids.each do |sid|
      message = Message.find_by(twilio_sid: sid)
      if message.nil?
        sids_not_found << sid
        error_message = "SID #{sid} NOT FOUND"
        puts "🔥 #{'!' * error_message.length} 🔥"
        puts "🔥 #{error_message} 🔥"
        puts "🔥 #{'!' * error_message.length} 🔥"
      else
        puts "    sid: #{sid}"
        status_emoji = '✅'
        status = message.twilio_status
        status = 'blank' if status.blank?
        status_emoji = '❌' if %w[blacklisted failed undelivered blank].include? status
        status_emoji = '🤔' if %w[accepted queued receiving sending sent maybe_undelivered].include? status
        puts " status: #{status_emoji} #{status.upcase}"
        inbound_emoji = message.inbound ? '⬅️' : '➡️'
        puts "inbound: #{inbound_emoji} #{message.inbound}"
        read_emoji = message.read ? '📭' : '📬'
        puts "   read: #{read_emoji} #{message.read}"
      end
      puts '----------'
    end

    joined_quoted_comma = sids_not_found.join("', '")
    joined_comma = sids_not_found.join(', ')
    joined_space = sids_not_found.join(' ')
    puts "\n#{sids_not_found.count} SIDs not found"
    next unless sids_not_found.count.positive?
    puts '----------'
    puts "'#{joined_quoted_comma}'"
    puts '----------'
    puts "'#{joined_comma}'"
    puts '----------'
    puts joined_space
  end

  #
  # run the tasks below locally
  #

  task get_carrier: :environment do |_, args|
    # usage: rake utils:get_carrier[app_name,phone_number_01,phone_number_02,...]
    #   args:
    #         app_name: the app name of the heroku deploy
    #         phone_number_xx: phone numbers in the format +14155551212

    if args.extras.empty? || args.extras.first.blank?
      puts 'no app name passed; usage: rake utils:get_carrier[app-name-here,+13035551212,+13035551213,...]'
    end

    app_name = args.extras.first
    phone_numbers = args.extras[1..-1]

    account_sid = Bundler.with_clean_env { `heroku config:get TWILIO_ACCOUNT_SID -a #{app_name}`.strip }
    auth_token = Bundler.with_clean_env { `heroku config:get TWILIO_AUTH_TOKEN -a #{app_name}`.strip }

    @client = Twilio::REST::Client.new account_sid, auth_token

    start_message = "getting carriers for #{phone_numbers.count} phone numbers"
    puts start_message
    puts '=' * start_message.length

    phone_numbers.each do |phone_number|
      begin
        response = @client.lookups.phone_numbers(phone_number).fetch(type: 'carrier')
      rescue Twilio::REST::RestError
        error_message = "#{phone_number} IS NOT VALID"
        puts Paint['!' * error_message.length, :black, :yellow]
        puts Paint[error_message, :black, :red]
        puts Paint['!' * error_message.length, :black, :yellow]
        puts '----------'
      else
        puts response.phone_number
        puts response.carrier['name']
        fore = :black
        back = :green
        back = :red if response.carrier['type'] == 'landline'
        puts Paint[response.carrier['type'].upcase, fore, back]
        puts '----------'
      end
    end
  end

  task :get_alerts, %i[app_name days_past] => :environment do |_, args|
    # usage: rake utils:get_alerts[app_name,days_past]
    #   args:
    #         app_name: the app name of the heroku deploy
    #         days_past: the number of days in the past to look for alerts (defaults to 3)

    if args.app_name.blank?
      puts 'no app name passed; usage: rake utils:get_alerts[app-name-here]'
      next
    end

    days_past = args.days_past.blank? ? 3 : args.days_past.to_i

    account_sid = Bundler.with_clean_env { `heroku config:get TWILIO_ACCOUNT_SID -a #{args.app_name}`.strip }
    auth_token = Bundler.with_clean_env { `heroku config:get TWILIO_AUTH_TOKEN -a #{args.app_name}`.strip }

    @client = Twilio::REST::Client.new account_sid, auth_token

    sids = []
    alerts = []
    start_date = Time.now.utc - days_past.days
    end_date = Time.now.utc + 1.day
    puts "getting alerts from #{start_date} to #{end_date}"

    %w[debug notice warning error].each do |log_level|
      @client.monitor.v1.alerts.list(
        start_date: start_date,
        end_date: end_date,
        log_level: log_level
      ).each do |a|
        alerts << a
      end
    end

    alerts = alerts.sort_by(&:date_created)

    alerts.each do |a|
      alert_text = a.alert_text.split('=')[-1].split('+').join(' ')
      request_url = a.request_url
      if request_url
        request_url.slice!(%r{https:\/\/})
        request_url.slice!(/\.clientcomm\.org/)
      end
      fore = :black
      back = :yellow
      if a.log_level.upcase.include? 'ERROR'
        fore = :white
        back = :red
      end
      puts Paint["#{a.log_level.upcase}_#{a.error_code}", fore, back]
      puts a.date_created
      puts "#{a.request_method} to #{request_url}"
      puts alert_text
      puts "https://www.twilio.com/console/runtime/debugger/#{a.sid}"
      puts "https://www.twilio.com/console/sms/logs/#{a.resource_sid}"
      puts '----------'
      sids << a.resource_sid
    end

    alerts_found = sids.count
    sids = sids.uniq
    messages_affected = sids.count

    joined_quoted_comma = sids.join("', '")
    joined_comma = sids.join(', ')
    joined_space = sids.join(' ')
    puts "\n#{alerts_found} alerts on #{messages_affected} messages found"
    next unless sids.count.positive?
    puts '----------'
    puts "'#{joined_quoted_comma}'"
    puts '----------'
    puts "'#{joined_comma}'"
    puts '----------'
    puts joined_space
  end
end
