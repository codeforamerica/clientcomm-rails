FactoryBot.define do
  factory :court_reminder do
    reporting_relationship { create :reporting_relationship }
    body { 'A fake Court Reminder' }
    sequence(:number_from) { Faker::PhoneNumber.cell_phone }
    sequence(:number_to) { Faker::PhoneNumber.cell_phone }
    court_date_csv { create :court_date_csv }
    send_at { Time.zone.now + 2.days }
  end
end
