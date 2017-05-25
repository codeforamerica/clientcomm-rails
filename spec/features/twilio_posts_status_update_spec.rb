require 'rails_helper'

feature 'Twilio' do
  before do
    user = create :user
    client = create :client, user: user, phone_number: params['From']
    create :message, user: user, client: client, twilio_sid: '49a5057738d311581dd5d005e97c2b5d0b', twilio_status: 'queued'
  end

  after :each do
    page.driver.header 'X-Twilio-Signature', nil
  end

  let(:params) do
    {"SmsSid"=>"49a5057738d311581dd5d005e97c2b5d0b", "SmsStatus"=>"delivered", "MessageStatus"=>"delivered", "To"=>"+12435551212", "MessageSid"=>"49a5057738d311581dd5d005e97c2b5d0b", "AccountSid"=>"077541f41cce52ea6c4944fa6823a4a277", "From"=>"+12425551212", "ApiVersion"=>"2010-04-01", "controller"=>"twilio", "action"=>"incoming_sms_status"}
  end

  describe 'POSTs to #incoming_sms_status' do
    context 'with incorrect signature' do
      it 'returns a forbidden response' do
        page.driver.post '/incoming/sms/status', params
        expect(page).to have_http_status(:forbidden)
      end
    end

    context 'with correct signature' do
      let(:correct_signature) do
        myhost = Capybara.current_host || Capybara.default_host
        Twilio::Util::RequestValidator.new(ENV['TWILIO_AUTH_TOKEN'])
          .build_signature_for("#{myhost}/incoming/sms/status", params)
      end

      it 'returns a no content response' do
        page.driver.header 'X-Twilio-Signature', correct_signature
        page.driver.post '/incoming/sms/status', params
        expect(page).to have_http_status(:no_content)
      end
    end
  end
end
