namespace :setup do
  task :unclaimed_account, [:unclaimed_email, :password, :admin_phone_number] => :environment do |_, args|
    user = User.find_or_initialize_by(email: args.unclaimed_email)
    user.update!(full_name: 'Unclaimed Clients', phone_number: args.admin_phone_number, password: args.password, password_confirmation: args.password)
  end
end
