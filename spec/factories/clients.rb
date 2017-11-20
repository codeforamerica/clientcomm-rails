FactoryBot.define do
  factory :client do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }
    notes { Faker::Lorem.sentence }
    client_status { ClientStatus.all.sample }

    transient do
      user { nil }
      active { true }
    end

    after(:create) do |client, evaluator|
      client.users << evaluator.user if evaluator.user
      client.reporting_relationships
            .find_by(user: evaluator.user)
            .update(active: evaluator.active)
    end
  end
end
