require 'rails_helper'

feature 'Twilio' do
  let(:message_params) { twilio_new_message_params }

  before do
    userone = create :user
    clientone = create :client, user: userone, phone_number: message_params['From']
    create :message, user: userone, client: clientone, twilio_sid: message_params['SmsSid'], twilio_status: message_params['SmsStatus']
  end

  after do
    twilio_clear_after
  end

  describe 'POSTs to #incoming_sms_status' do
    context 'with incorrect signature' do
      it 'returns a forbidden response' do
        page.driver.post '/incoming/sms/status', message_params
        expect(page).to have_http_status(:forbidden)
      end
    end

    context 'with correct signature' do
      let(:correct_signature) do
        myhost = Capybara.current_host || Capybara.default_host
        Twilio::Util::RequestValidator.new(ENV['TWILIO_AUTH_TOKEN'])
          .build_signature_for("#{myhost}/incoming/sms/status", message_params)
      end

      it 'returns a no content response' do
        page.driver.header 'X-Twilio-Signature', correct_signature
        page.driver.post '/incoming/sms/status', message_params
        expect(page).to have_http_status(:no_content)
      end
    end
  end
end
