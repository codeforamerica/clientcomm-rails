namespace :setup do
  task :admin_account, [:admin_email, :password] => :environment do |_, args|
    user = AdminUser.find_or_initialize_by(email: args.admin_email)
    user.update!(password: args.password, password_confirmation: args.password)
  end

  task :unclaimed_account, [:unclaimed_email, :password] => :environment do |_, args|
    user = User.find_or_initialize_by(email: args.unclaimed_email)
    user.update!(full_name: 'Unclaimed User', password: args.password, password_confirmation: args.password)
  end

  task :install_department, [:department_name] => :environment do |_, args|
    unclaimed_user = User.find_by(email: ENV['UNCLAIMED_EMAIL'])

    department = Department.create(
      name: args.department_name || 'Main',
      phone_number: ENV['TWILIO_PHONE_NUMBER']
    )

    User.all.each do |user|
      user.update!(department: department)
    end

    department.update!(unclaimed_user: unclaimed_user)
  end

  task :migrate_metadata_from_client_to_relationship => :environment do
    count = Client.all.count - 1
    Client.all.each_with_index do |client, i|
      progress = 50.0 * (i / count.to_f)

      bar = '#' * progress.to_i
      space = ' ' * (50 - progress.to_i)
      print "\r|#{bar}#{space}|"

      client.reporting_relationships.each do |rr|
        rr.notes = client['notes']
        rr.has_message_error = client['has_message_error']
        rr.has_unread_messages = client['has_unread_messages']
        rr.last_contacted_at = client['last_contacted_at']
        rr.client_status_id = client['client_status_id']
        rr.save!
      end
    end

    puts "\nComplete"
  end
end
