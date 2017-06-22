FactoryGirl.define do
  factory :attachment do
    url { "https://api.twilio.com/2010-04-01/Accounts/" + SecureRandom.hex(17) +
      "/Messages/" + SecureRandom.hex(17) +
      "/Media/" + SecureRandom.hex(17) }
    content_type { ["image/jpeg", "image/png", "image/gif"].sample }
    message { create :message }
    width { [640, 800, 1024].sample }
    height { (width * 0.75).to_i }
  end
end
