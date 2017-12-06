FactoryBot.define do
  factory :client do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }
    notes { Faker::Lorem.sentence }

    transient do
      user { nil }
      active { true }
      client_status { nil }
    end

    after(:create) do |client, evaluator|
      if evaluator.user
        client.users << evaluator.user
        client.reporting_relationships
              .find_by(user: evaluator.user)
              .update(active: evaluator.active, client_status: evaluator.client_status)
      end
    end
  end
end
