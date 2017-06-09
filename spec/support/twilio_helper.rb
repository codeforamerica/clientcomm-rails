module TwilioHelper
  def twilio_post_sms(tw_params = nil)
    tw_params ||= twilio_new_message_params()
    if Capybara.current_session.server
      conn = Faraday.new("#{myhost}")
      conn.post do |req|
        req.url '/incoming/sms'
        req.headers['X-Twilio-Signature'] = correct_signature(tw_params)
        req.body = tw_params
      end
    else
      page.driver.header 'X-Twilio-Signature', correct_signature(tw_params)
      page.driver.post '/incoming/sms', tw_params
    end
  end

  def twilio_message_text
    "This is a test message."
  end

  def twilio_new_message_params(from_number = nil, sms_sid = nil)
    from_number ||= '+12425551212'
    sms_sid ||= SecureRandom.hex(17)
    {
      "ToCountry"=>"US",
      "ToState"=>"CA",
      "SmsMessageSid"=>sms_sid,
      "NumMedia"=>"0",
      "ToCity"=>"",
      "FromZip"=>"94005",
      "SmsSid"=>sms_sid,
      "FromState"=>"CA",
      "SmsStatus"=>"received",
      "FromCity"=>"SAN FRANCISCO",
      "Body"=>twilio_message_text,
      "FromCountry"=>"US",
      "To"=>"+12435551212",
      "ToZip"=>"",
      "AddOns"=>"{\"status\":\"successful\",\"message\":null,\"code\":null,\"results\":{}}",
      "NumSegments"=>"1",
      "MessageSid"=>sms_sid,
      "AccountSid"=>"077541f41cce52ea6c4944fa6823a4a277",
      "From"=>from_number,
      "ApiVersion"=>"2010-04-01",
      "controller"=>"twilio",
      "action"=>"incoming_sms"
    }
  end

  private

  def myhost
    if Capybara.current_session.server
      return "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
    end
    Capybara.current_host || Capybara.default_host
  end

  def correct_signature(tw_params = nil)
    tw_params ||= twilio_new_message_params()
    Twilio::Util::RequestValidator.new(ENV['TWILIO_AUTH_TOKEN'])
      .build_signature_for("#{myhost}/incoming/sms", tw_params)
  end
end
