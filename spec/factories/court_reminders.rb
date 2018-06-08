FactoryBot.define do
  factory :court_reminder do
    reporting_relationship { create :reporting_relationship }
    body { "A fake Court Reminder #{SecureRandom.hex(17)}" }
    court_date_csv { create :court_date_csv }
    send_at { Time.zone.now + 2.days }
  end
end
