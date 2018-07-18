# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# pass passwords to db:reset, db:setup, or db:seed like so:
# `upw=myuserpassword apw=myadminpassword rails db:seed`
user_password = ENV['upw'] || ENV['UPW'] || ENV['USER_PASSWORD'] || SecureRandom.hex(14)
admin_password = ENV['apw'] || ENV['APW'] || ENV['ADMIN_PASSWORD'] || user_password

puts 'Populating Feature Flags'
FeatureFlag.find_or_create_by(flag: 'scheduled_message_count').update!(enabled: true)
FeatureFlag.find_or_create_by(flag: 'court_dates').update!(enabled: true)
FeatureFlag.find_or_create_by(flag: 'hide_notes').update!(enabled: true)
FeatureFlag.find_or_create_by(flag: 'client_id_number').update!(enabled: true)
FeatureFlag.find_or_create_by(flag: 'categories').update!(enabled: true)
FeatureFlag.find_or_create_by(flag: 'client_status').update!(enabled: false)
FeatureFlag.find_or_create_by(flag: 'templates').update!(enabled: false)
FeatureFlag.find_or_create_by(flag: 'mass_messages').update!(enabled: true)

puts "Creating Admin User with password #{admin_password}"
AdminUser.find_or_create_by(email: 'admin@example.com').update!(password: admin_password, password_confirmation: admin_password) if Rails.env.development?

puts "Creating Test User with password #{user_password}"
test_user = User.find_or_create_by(email: 'test@example.com')
test_user.update!(full_name: 'Test Example', password: user_password, department: nil, treatment_group: 'ebp-liking-messages')

puts 'Deleting Old Records'
Attachment.delete_all
Message.delete_all
ReportingRelationship.delete_all
Client.delete_all
Department.destroy_all
User.where.not(id: [test_user.id]).delete_all
Survey.delete_all

puts 'Creating Departments'
FactoryBot.create_list :department, 3
User.all.each do |user|
  user.update(department: Department.all.sample)
end

puts 'Create Client Status'
Department.all.each do |dept|
  FactoryBot.create_list :client_status, rand(1..5), department: dept
end

test_user.reload.department.update(phone_number: ENV['TWILIO_PHONE_NUMBER'])

puts 'Creating Survey Questions and Responses'
FactoryBot.create :survey_question
SurveyQuestion.all.each do |question|
  FactoryBot.create_list :survey_response, 6, survey_question: question
end

puts 'Creating Users and Clients'
Department.all.each do |department|
  FactoryBot.create_list :user, 3, department: department
  unclaimed_user = FactoryBot.create :user, full_name: 'Unclaimed User', department: department
  department.unclaimed_user = unclaimed_user
  department.save

  department.users.where.not(id: department.unclaimed_user.id).each do |user|
    FactoryBot.create_list :client, 5, user: user
  end
end

puts 'Transferring Clients'
Client.all.sample(15).each do |client|
  client_user = client.users.first
  client_dept = client_user.department
  client_rr = ReportingRelationship.find_by(user: client_user, client: client)
  new_user = User.where(department: client_dept).where.not(id: client_user.id).order('RANDOM()').first
  new_rr = ReportingRelationship.find_or_initialize_by(user_id: new_user.id, client_id: client.id)
  client_rr.transfer_to(new_rr)
end

puts 'Giving Test User Some Extra Clients'
FactoryBot.create_list :client, 15, user: test_user

puts 'Fuzzing Clients'
Client.all.sample(15).each do |client|
  existing_users = client.users
  client.users << User.where.not(department: existing_users.map(&:department)).sample
end

puts 'Creating Messages'
ReportingRelationship.all.each do |rr|
  rr.update!(client_status_id: ClientStatus.all.sample.id)
  FactoryBot.create_list :text_message, 10, reporting_relationship: rr, read: true
end

puts 'Creating Attachments'
ReportingRelationship.all.each do |rr|
  messages = FactoryBot.create_list :text_message, 2, reporting_relationship: rr, read: true
  messages.each do |msg|
    FactoryBot.create :attachment, message: msg
  end
end

puts 'Creating Court Reminders'
third = (ReportingRelationship.all.count * 0.33).to_i
ReportingRelationship.all.sample(third).each do |rr|
  FactoryBot.create :court_reminder, reporting_relationship: rr
end

puts 'Creating Client Edit Markers'
ReportingRelationship.all.sample(third).each do |rr|
  FactoryBot.create :client_edit_marker, reporting_relationship: rr
end
