FactoryBot.define do
  factory :admin_user do
    sequence(:email) { Faker::Internet.unique.email }
    sequence(:password) { Faker::Internet.unique.password }
  end
end
