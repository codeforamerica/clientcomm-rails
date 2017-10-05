# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

User.create!(full_name: 'Test Example', email: 'test@example.com', password: 'changeme')
User.create!(full_name: 'Unclaimed Email', email: ENV['UNCLAIMED_EMAIL'], password: 'changeme')
AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?

FactoryGirl.create_list :user, 3
User.all.each do |user|
  FactoryGirl.create_list :client, 10, user: user
end

Client.all.each do |client|
  FactoryGirl.create_list :message, 10, user: client.user, client: client
end

FeatureFlag.find_by_flag('mass_messages').update!(enabled: true)
FeatureFlag.find_by_flag('templates').update!(enabled: true)
