# usage: rake utils:get_alerts[app_name,days_past]
#   args:
#      app_name: the app name of the heroku deploy
#     days_past: the number of days in the past to look for alerts (defaults to 3)

namespace :utils do
  task :get_alerts, %i[app_name days_past] => :environment do |_, args|
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

    joined_comma = sids.join("', '")
    joined_space = sids.join(' ')
    puts "#{alerts_found} alerts on #{messages_affected} messages found"
    next unless sids.count.positive?
    puts '----------'
    puts "'#{joined_comma}'"
    puts '----------'
    puts joined_space
  end
end
