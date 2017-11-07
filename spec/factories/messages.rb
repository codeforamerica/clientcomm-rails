FactoryBot.define do
  factory :message do
    user { create :user }
    client { create :client, user: user }
    body { "i am a message #{SecureRandom.hex(17)}" }
    sequence(:number_from) { Faker::PhoneNumber.cell_phone }
    sequence(:number_to) { Faker::PhoneNumber.cell_phone }
    inbound { [true, false].sample }
    sequence(:twilio_sid) { |n| (n.to_s + SecureRandom.hex(17))[0..33] }
    twilio_status { ["accepted", "queued", "sending", "sent", "receiving", "received", "delivered", "undelivered", "failed"].sample }
    send_at { Time.current }
  end
end
