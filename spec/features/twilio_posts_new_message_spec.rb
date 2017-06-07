require 'rails_helper'

feature 'Twilio' do
  before do
    user = create :user
    create :client, user: user, phone_number: twilio_params['From']
  end

  after do
    page.driver.header 'X-Twilio-Signature', nil
  end

  describe 'POSTs to #incoming_sms' do
    context 'with incorrect signature' do
      it 'returns a forbidden response' do
        page.driver.post '/incoming/sms', twilio_params
        expect(page).to have_http_status(:forbidden)
      end
    end

    context 'with correct signature' do
      it 'returns a no content response' do
        twilio_post_sms
        expect(page).to have_http_status(:no_content)
      end
    end
  end
end
