FactoryBot.define do
  factory :text_message do
    reporting_relationship { create :reporting_relationship }
    body { "i am a message #{SecureRandom.hex(17)}" }
    inbound { [true, false].sample }
    sequence(:twilio_sid) { |n| (n.to_s + SecureRandom.hex(17))[0..33] }
    twilio_status { %w[accepted queued sending sent receiving received delivered undelivered failed].sample }
    send_at { Time.current }
  end
end
