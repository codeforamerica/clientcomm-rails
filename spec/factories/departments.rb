FactoryBot.define do
  factory :department do
    sequence(:name) { |n| "Department#{n}" }
    phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }
  end
end
