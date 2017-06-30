FactoryGirl.define do
  factory :message do
    user { create :user }
    client { create :client, user: user }
    body "This is the body of a fake SMS message"
    sequence(:number_from) { |n| "243" + (n.to_s + (1000000 + Random.rand(10000000 - 1000000)).to_s)[0..6] }
    sequence(:number_to) { |n| "244" + (n.to_s + (1000000 + Random.rand(10000000 - 1000000)).to_s)[0..6] }
    inbound {[true, false].sample}
    sequence(:twilio_sid) { |n| (n.to_s + SecureRandom.hex(17))[0..33] }
    twilio_status {["accepted", "queued", "sending", "sent", "receiving", "received", "delivered", "undelivered", "failed"].sample} end
end
