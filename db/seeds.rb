# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts 'Populating Feature Flags'
FeatureFlag.find_or_create_by(flag: 'mass_messages').update!(enabled: true)
FeatureFlag.find_or_create_by(flag: 'templates').update!(enabled: true)
FeatureFlag.find_or_create_by(flag: 'client_status').update!(enabled: true)

puts 'Populating Client Statuses'
ClientStatus.find_or_create_by!(name: 'Exited', followup_date: 90)
ClientStatus.find_or_create_by!(name: 'Training', followup_date: 30)
ClientStatus.find_or_create_by!(name: 'Active', followup_date: 30)

test_department = Department.find_or_create_by!(name: 'Test', phone_number: "+1760555#{Faker::PhoneNumber.unique.subscriber_number}")

puts "Creating Admin User"
AdminUser.find_or_create_by(email: 'admin@example.com').update!(password: 'changeme', password_confirmation: 'changeme') if Rails.env.development?

puts "Creating Test Users"
User.find_or_create_by(email: 'test@example.com').update!(full_name: 'Test Example', password: 'changeme', department: test_department)
User.find_or_create_by(email: ENV['UNCLAIMED_EMAIL']).update!(full_name: 'Unclaimed Email', password: 'changeme', department: test_department)

puts "Creating Sample Users"
FactoryBot.create_list :user, 3, department: test_department

puts 'Creating Clients'
User.all.each do |user|
  FactoryBot.create_list :client, 10, user: user
end

puts 'Creating Messages'
Client.all.each do |client|
  FactoryBot.create_list :message, 10, user: client.user, client: client
end
