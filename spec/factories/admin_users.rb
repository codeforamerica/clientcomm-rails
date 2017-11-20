FactoryBot.define do
  factory :admin_user do
    email { Faker::Internet.unique.email }
    password { Faker::Internet.unique.password }
  end
end
