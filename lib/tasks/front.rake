namespace :front do
  task :migrate, [:email] => :environment do |t, args|
      FrontImport.new(front_token: ENV['FRONT_AUTH_TOKEN']).import(email: args[:email])
  end
end
