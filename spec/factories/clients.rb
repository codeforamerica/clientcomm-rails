FactoryGirl.define do
  factory :client do
    sequence(:first_name) { |n| "Elsie#{n}" }
    sequence(:last_name) { |n| "Muller#{n}" }
    birth_date do
      from = 50.years.ago.to_f
      to = 20.years.ago.to_f
      Time.at(from + rand * (to - from))
    end
    sequence(:phone_number) { |n| "243" + (10**6 + n).to_s[0..6] }
    active true
  end
end
