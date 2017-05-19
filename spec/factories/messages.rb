FactoryGirl.define do
  factory :message do
    client nil
    user nil
    body "MyString"
    number_from "MyString"
    number_to "MyString"
    inbound false
    twilio_sid "MyString"
    twilio_status "MyString"
  end
end
