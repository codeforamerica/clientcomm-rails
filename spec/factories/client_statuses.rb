FactoryGirl.define do
  factory :client_status do
    sequence(:name) { Faker::Lorem.word }
  end
end
