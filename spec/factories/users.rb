FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "me#{n}@example.com" }
    sequence(:password) { |n| "myc00l#{n}password" }
  end
end
