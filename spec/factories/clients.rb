FactoryGirl.define do
  factory :client do
    user { create :user }
    sequence(:first_name) { Faker::Name.first_name }
    sequence(:last_name) { Faker::Name.last_name }
    sequence(:phone_number) { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }
    sequence(:notes) { Faker::Lorem.sentence }
    active true
  end
end
