require 'rails_helper'

feature 'Twilio' do
  let(:message_params) { twilio_new_message_params }

  before do
    userone = create :user
    clientone = create :client, user: userone, phone_number: message_params['From']
    create :message, user: userone, client: clientone, twilio_sid: message_params['SmsSid'], twilio_status: 'queued'
  end

  after do
    twilio_clear_after
  end

  describe 'POSTs to #incoming_sms_status' do
    context 'with incorrect signature' do
      it 'returns a forbidden response' do
        # send false as 2nd argument to send bad signature
        twilio_post_sms_status message_params, false
        expect(page).to have_http_status(:forbidden)
      end
    end

    context 'with correct signature' do
      it 'returns a no content response' do
        twilio_post_sms_status message_params
        expect(page).to have_http_status(:no_content)
      end
    end
  end
end
