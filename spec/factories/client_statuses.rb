FactoryGirl.define do
  factory :client_status do
    sequence(:name) { Faker::Lorem.word }
    followup_date { rand(1..100) }
  end
end
