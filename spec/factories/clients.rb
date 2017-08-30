FactoryGirl.define do
  factory :client do
    user { create :user }
    sequence(:first_name) { Faker::Name.first_name }
    sequence(:last_name) { Faker::Name.last_name }
    sequence(:phone_number) { Faker::PhoneNumber.unique.cell_phone }
    sequence(:notes) { Faker::Lorem.sentence }
    active true
  end
end
