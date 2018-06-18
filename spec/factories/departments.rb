FactoryBot.define do
  factory :department do
    sequence(:name) { |n| "Department#{n}" }
    phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }

    after(:create) do |dept, evaluator|
      unless evaluator.unclaimed_user
        dept.update!(unclaimed_user: create(:user, phone_number: nil, full_name: 'Unclaimed', department: dept))
      end
    end
  end
end
