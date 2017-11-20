namespace :setup do
  task :admin_account, [:admin_email, :password] => :environment do |_, args|
    user = AdminUser.find_or_initialize_by(email: args.admin_email)
    user.update!(password: args.password, password_confirmation: args.password)
  end

  task :install_department, [:department_name] => :environment do |_, args|
    unclaimed_user = User.find_by(email: ENV['UNCLAIMED_EMAIL'])

    department = Department.create(
      name: args.department_name,
      phone_number: ENV['TWILIO_PHONE_NUMBER']
    )

    User.all.each do |user|
      user.update!(department: department)
    end

    department.update!(unclaimed_user: unclaimed_user)
  end
end
