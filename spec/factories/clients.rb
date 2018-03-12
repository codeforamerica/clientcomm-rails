FactoryBot.define do
  factory :client do
    first_name { 'FirstName' }
    sequence(:last_name) { |n| "LastName#{n}" }
    phone_number { "+1760555#{Faker::PhoneNumber.unique.subscriber_number}" }

    transient do
      user { nil }
      active { true }
      client_status { nil }
      notes { Faker::Lorem.sentence }
      has_message_error { false }
      has_unread_messages { false }
    end

    after(:create) do |client, evaluator|
      if evaluator.user
        client.users << evaluator.user
        client.reporting_relationships
              .find_by(user: evaluator.user)
              .update(
                active: evaluator.active,
                client_status: evaluator.client_status,
                notes: evaluator.notes,
                has_message_error: evaluator.has_message_error,
                has_unread_messages: evaluator.has_unread_messages
              )
      end
    end
  end
end
