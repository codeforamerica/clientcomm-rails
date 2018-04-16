require 'csv'

namespace :reports do
  task :long_messages => :environment do
    io = $stdout.dup
    CSV(io) do |csv|
      csv << %w[name email client id length timestamp]
      Message.messages.where('length(body) > 1600').find_each do |msg|
        csv << [msg.user.full_name, msg.user.email, msg.client.full_name, msg.id, msg.body.length, msg.created_at]
      end
    end
  end
end
