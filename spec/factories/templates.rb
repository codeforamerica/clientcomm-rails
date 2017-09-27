FactoryGirl.define do
  factory :template do
    user { create :user }
    sequence(:title) { Faker::Lorem.sentence }
    sequence(:body) { Faker::Lorem.sentence }
  end
end
