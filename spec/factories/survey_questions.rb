FactoryBot.define do
  factory :survey_question do
    text { Faker::Lorem.sentence }
  end
end
