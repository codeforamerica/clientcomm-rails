FactoryBot.define do
  factory :department do
    name { Faker::Company.name }
    phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }
  end
end
