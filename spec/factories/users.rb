FactoryGirl.define do
  factory :user do
    sequence(:email) { Faker::Internet.unique.email }
    sequence(:password) { Faker::Internet.unique.password }
    sequence(:full_name) { Faker::Name.name }
  end
end
