FactoryGirl.define do
  factory :template do
    user { create :user }
    sequence(:title) { Faker::Lorem.sentence(4, false, 0) }
    sequence(:body) { Faker::Lorem.sentence }
  end
end
