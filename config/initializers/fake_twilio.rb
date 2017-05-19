if Rails.env.test? || Rails.env.development?
  require File.expand_path("#{Rails.root}/spec/fake_twilio_client")
  Twilio::REST.send(:remove_const, :Client) 
  Twilio::REST::Client = FakeTwilioClient
end
