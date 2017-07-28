FactoryGirl.define do
  factory :client do
    user { create :user }
    sequence(:first_name) { Faker::Name.unique.first_name }
    sequence(:last_name) { Faker::Name.unique.last_name }
    sequence(:phone_number) { Faker::PhoneNumber.unique.cell_phone }
    active true
  end
end
