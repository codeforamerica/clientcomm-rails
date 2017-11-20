FactoryBot.define do
  factory :department do
    name "MyString"
    phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }
  end
end
