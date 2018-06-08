FactoryBot.define do
  factory :court_reminder do
    reporting_relationship { create :reporting_relationship }
    body { "i am a court reminder #{SecureRandom.hex(17)}" }
    court_date_csv { create :court_date_csv }
    send_at { Time.zone.now + 2.days }
  end
end
