require "rails_helper"

feature 'Twilio posts to #incoming_sms with an incorrect signature' do
  before do
    user = create :user
    create :client, user: user, phone_number: params['From']
  end

  after do
    page.driver.header 'X-Twilio-Signature', nil
  end

  let(:params) do
    {"ToCountry"=>"US", "ToState"=>"CA", "SmsMessageSid"=>"49a5057738d311581dd5d005e97c2b5d0b", "NumMedia"=>"0", "ToCity"=>"", "FromZip"=>"94005", "SmsSid"=>"49a5057738d311581dd5d005e97c2b5d0b", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"SAN FRANCISCO", "Body"=>"This is a test message.", "FromCountry"=>"US", "To"=>"+12435551212", "ToZip"=>"", "AddOns"=>"{\"status\":\"successful\",\"message\":null,\"code\":null,\"results\":{}}", "NumSegments"=>"1", "MessageSid"=>"49a5057738d311581dd5d005e97c2b5d0b", "AccountSid"=>"077541f41cce52ea6c4944fa6823a4a277", "From"=>"+12425551212", "ApiVersion"=>"2010-04-01", "controller"=>"twilio", "action"=>"incoming_sms"}
  end

  describe 'POST #incoming_sms' do
    context 'POST with incorrect signature' do
      it 'returns a forbidden response' do
        page.driver.post '/incoming/sms', params
        expect(page).to have_http_status(:forbidden)
      end
    end

    context 'POST with correct signature' do
      let(:correct_signature) do
        Twilio::Util::RequestValidator.new(ENV['TWILIO_AUTH_TOKEN'])
          .build_signature_for("#{Capybara.current_host}/incoming/sms", params)
      end

      it 'returns a no content response' do
        page.driver.header 'X-Twilio-Signature', correct_signature
        page.driver.post '/incoming/sms', params
        expect(page).to have_http_status(:no_content)
      end
    end
  end
end
