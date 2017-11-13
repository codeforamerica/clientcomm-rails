namespace :surveys do
  task :scheduled_messages => :environment do
    users = User.select('users.id, users.full_name, users.email, messages.send_at, left(messages.body, 20) as body')
                .joins(:messages).where("messages.send_at - messages.created_at > '1 hour'::interval")
                .where(messages: { send_at: (Time.now - 48.hours)..(Time.now - 24.hours) })
                .where(messages: { sent: true })

    users.each do |user|
      puts ''
      puts "#{user[:full_name]} <#{user[:email]}>"
      puts "message: #{user[:body]}..."
      puts "on: #{user[:send_at].in_time_zone(Time.zone).strftime('%A, %B %-d, %-l:%M%p; %Z')}"
      puts '################################'
    end
  end
end
