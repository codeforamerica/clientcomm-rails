FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { Faker::Internet.unique.password }
    full_name { Faker::Name.name }
    phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }

    transient do
      dept_phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }
    end

    department do
      create :department, phone_number: dept_phone_number
    end
  end
end
