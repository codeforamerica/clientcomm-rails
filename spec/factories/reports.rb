FactoryBot.define do
  factory :report do
    email { Faker::Internet.unique.email }
    department nil
  end
end
