FactoryBot.define do
  factory :survey_response do
    text { Faker::Lorem.sentence }
    survey_question nil
  end
end
