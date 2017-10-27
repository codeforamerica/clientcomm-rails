FactoryBot.define do
  factory :user do
    sequence(:email) { Faker::Internet.unique.email }
    sequence(:password) { Faker::Internet.unique.password }
    sequence(:full_name) { Faker::Name.name }
    sequence(:phone_number) { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }
  end
end
