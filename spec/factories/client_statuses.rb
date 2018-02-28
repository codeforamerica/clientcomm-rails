FactoryBot.define do
  factory :client_status do
    sequence(:name) { Faker::Lorem.word }
    followup_date { nil }
    icon_color { "\##{SecureRandom.hex(3)}" }
    department do
      create :department
    end
  end
end
