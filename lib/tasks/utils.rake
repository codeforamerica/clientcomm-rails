namespace :utils do
  ################################
  # run the tasks below remotely #
  ################################

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
        error_emoji = '🔥'
        error_message = "#{sid} WAS NOT FOUND"
        if sid.start_with? 'CA'
          error_emoji = '📞'
          error_message = "#{sid} IS PHONE CALL"
        end
        puts "#{error_emoji} #{'!' * error_message.length} #{error_emoji}"
        puts "#{error_emoji} #{error_message} #{error_emoji}"
        puts "#{error_emoji} #{'!' * error_message.length} #{error_emoji}"
      else
        puts "    sid: #{sid}"
        status_emoji = '✅'
        status = message.twilio_status
        status = 'blank' if status.blank?
        status_emoji = '❌' if %w[blacklisted failed undelivered blank].include? status
        status_emoji = '🤔' if %w[accepted queued receiving sending sent maybe_undelivered].include? status
        puts " status: #{status_emoji} #{status.upcase}"
        inbound_text = message.inbound ? '📥 true' : '   false 📤'
        puts "inbound: #{inbound_text}"
        read_text = message.read ? '📭 true' : '   false 📬'
        puts "   read: #{read_text}"
      end
      puts '----------'
    end

    joined_comma_quoted = sids_not_found.join("', '")
    joined_comma = sids_not_found.join(',')
    joined_space = sids_not_found.join(' ')
    puts "\n#{sids_not_found.count} SIDs not found"
    next unless sids_not_found.count.positive?
    puts '----------'
    puts "'#{joined_comma_quoted}'"
    puts '----------'
    puts joined_comma
    puts '----------'
    puts joined_space
  end

  task :deliver_message, %i[message_sid body] => :environment do |_, args|
    # usage: heroku run rake utils:deliver_message[message_sid,body] -a clientcom-xxx
    #   args:
    #         message_sid: the Twilio SID of the message
    #                body: (optional) the message text

    if args.message_sid.blank? || args.message_sid.length != 34 || args.message_sid.match(/\s/)
      puts 'invalid message sid passed; must be non nil, 34 characters long, and contain no spaces'
      puts 'usage: heroku run rake utils:deliver_message[SM1a...,optional message text]'
      next
    end

    unless Message.find_by(twilio_sid: args.message_sid).nil?
      puts 'message with that sid already exists!'
      next
    end

    begin
      twilio_message = SMSService.instance.message_lookup(twilio_sid: args.message_sid)
    rescue Twilio::REST::RestError => e
      puts "error #{e.code} for sid #{args.message_sid}"
      next
    end

    twilio_params = SMSService.instance.twilio_params(twilio_message: twilio_message)
    twilio_params[:Body] = args.body if args.body.present?

    begin
      new_message = Message.create_from_twilio! twilio_params
    rescue StandardError => e
      puts "#{e.class} for sid #{args.message_sid}: #{e.message}"
      next
    end

    new_message.update!(send_at: twilio_message.date_sent)
    MessageHandler.handle_new_message(message: new_message)
  end

  ###############################
  # run the tasks below locally #
  ###############################

  task get_okr_stats: :environment do |_, args|
    # usage: rake utils:get_okr_stats[weeks]
    #   args:
    #         weeks: the number of weeks ago for which to run the queries (defaults to 0, this week)

    weeks = args.extras.first.blank? ? 0 : args.extras.first.to_i

    span_start = "DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'"
    span_end = "DATE_TRUNC('week', CURRENT_DATE)"
    message_start = 'Getting OKR stats for this week.'

    if weeks.positive?
      span_start = "DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '#{weeks + 1} weeks'"
      end_interval = weeks > 1 ? "#{weeks} weeks" : "#{weeks} week"
      span_end = "DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '#{end_interval}'"
      message_start = "Getting OKR stats for #{end_interval} ago."
    end

    puts message_start

    query_active_clients = 'SELECT COUNT(DISTINCT(cl.id)) '\
                           'FROM clients cl '\
                           'INNER JOIN reporting_relationships rr ON rr.client_id = cl.id '\
                           'INNER JOIN users us ON us.id = rr.user_id '\
                           "WHERE us.email NOT ILIKE '%codefor%' "\
                           "AND cl.created_at < #{span_end} and rr.active = true;"

    query_closed_prefix = 'SELECT COUNT(*) FROM surveys s '\
                          'INNER JOIN survey_response_links srl ON srl.survey_id = s.id '\
                          'INNER JOIN survey_responses sr ON sr.id = srl.survey_response_id '\
                          'INNER JOIN survey_questions sq ON sq.id = sr.survey_question_id '\
                          "WHERE s.created_at < #{span_end} "\
                          "AND s.created_at > #{span_start} "\
                          "AND sq.text ILIKE '%outcome%' AND"

    query_closed_successful = "#{query_closed_prefix} sr.text ILIKE '%successful%';"

    suffix_unsuccessful_a = "sr.text ILIKE '%unsuccessful%'"
    suffix_unsuccessful_b = "(sr.text ILIKE '%revoked%' OR sr.text ILIKE '%absconded%')"
    suffix_unsuccessful_c = "(sr.text ILIKE '%rescinded%' OR sr.text ILIKE '%fta%')"

    suffix_unknown_a = "(sr.text ILIKE '%transferred%' OR sr.text ILIKE '%other%')"
    suffix_unknown_b = "sr.text ILIKE '%open%'"

    query_closed_all = 'SELECT COUNT(*) FROM reporting_relationships rr '\
                       'WHERE rr.active = false '\
                       'AND (SELECT COUNT(*) FROM reporting_relationships rb '\
                            'WHERE rb.client_id = rr.client_id '\
                            'AND rb.active = true) = 0 '\
                       "AND rr.updated_at < #{span_end} "\
                       "AND rr.updated_at > #{span_start};"

    query_closed_successful_total = 'SELECT COUNT(*) FROM surveys s '\
                                    'INNER JOIN survey_response_links srl ON srl.survey_id = s.id '\
                                    'INNER JOIN survey_responses sr ON sr.id = srl.survey_response_id '\
                                    'INNER JOIN survey_questions sq ON sq.id = sr.survey_question_id '\
                                    "WHERE s.created_at < #{span_end} "\
                                    "AND sq.text ILIKE '%outcome%' "\
                                    "AND sr.text ILIKE '%successful%';"

    deploys = %w[slco multco baltimore pima 5cbc danecrc georgiadcs cccounty]

    stats = {
      active_clients: [],
      closed_successful: [],
      closed_unsuccessful: [],
      closed_unknown: [],
      closed_all: [],
      closed_successful_total: []
    }

    deploys.each do |deploy|
      puts "...getting stats for #{deploy}"
      suffix_unsuccessful = if %w[slco].include?(deploy)
                              suffix_unsuccessful_a
                            elsif %w[multco pima danecrc georgiadcs].include?(deploy)
                              suffix_unsuccessful_b
                            elsif %w[baltimore 5cbc cccounty].include?(deploy)
                              suffix_unsuccessful_c
                            end

      suffix_unknown = if %w[slco multco pima danecrc georgiadcs].include?(deploy)
                         suffix_unknown_a
                       elsif %w[baltimore 5cbc cccounty].include?(deploy)
                         suffix_unknown_b
                       end

      query_closed_unsuccessful = "#{query_closed_prefix} #{suffix_unsuccessful};"
      query_closed_unknown = "#{query_closed_prefix} #{suffix_unknown};"

      database_url = Bundler.with_clean_env { `heroku config:get DATABASE_URL -a clientcomm-#{deploy}`.strip }
      stats[:active_clients] << Bundler.with_clean_env { `echo "#{query_active_clients}" | psql -t #{database_url}`.strip }
      puts "   > active clients: #{stats[:active_clients].last}"
      stats[:closed_successful] << Bundler.with_clean_env { `echo "#{query_closed_successful}" | psql -t #{database_url}`.strip }
      puts "   > closed successful: #{stats[:closed_successful].last}"
      stats[:closed_unsuccessful] << Bundler.with_clean_env { `echo "#{query_closed_unsuccessful}" | psql -t #{database_url}`.strip }
      puts "   > closed unsuccessful: #{stats[:closed_unsuccessful].last}"
      stats[:closed_unknown] << Bundler.with_clean_env { `echo "#{query_closed_unknown}" | psql -t #{database_url}`.strip }
      puts "   > closed unknown: #{stats[:closed_unknown].last}"
      stats[:closed_all] << Bundler.with_clean_env { `echo "#{query_closed_all}" | psql -t #{database_url}`.strip }
      puts "   > closed all: #{stats[:closed_all].last}"
      stats[:closed_successful_total] << Bundler.with_clean_env { `echo "#{query_closed_successful_total}" | psql -t #{database_url}`.strip }
      puts "   > closed successful total: #{stats[:closed_successful_total].last}"
    end

    puts '----------'

    stats.each_key do |key|
      puts "#{key}: =#{stats[key].join('+')}"
    end
  end

  task get_carrier: :environment do |_, args|
    # usage: rake utils:get_carrier[app_name,phone_number_01,phone_number_02,...]
    #   args:
    #         app_name: the app name of the heroku deploy
    #         phone_number_xx: phone numbers in the format +14155551212

    if args.extras.empty? || args.extras.first.blank?
      puts 'no app name passed; usage: rake utils:get_carrier[app-name-here,+13035551212,+13035551213,...]'
      next
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

    joined_comma_quoted = sids.join("', '")
    joined_comma = sids.join(',')
    joined_space = sids.join(' ')
    puts "\n#{alerts_found} alerts on #{messages_affected} messages found"
    next unless sids.count.positive?
    puts '----------'
    puts "'#{joined_comma_quoted}'"
    puts '----------'
    puts joined_comma
    puts '----------'
    puts joined_space
  end
end
