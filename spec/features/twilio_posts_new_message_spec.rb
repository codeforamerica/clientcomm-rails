require 'rails_helper'

feature 'Twilio' do
  let(:phone_number) { 'something explicit' }
  let(:department) { create :department, phone_number: phone_number }

  before do
    user = create :user, department: department
    create :client, user: user, phone_number: twilio_new_message_params['From']
  end

  after do
    page.driver.header 'X-Twilio-Signature', nil
  end

  describe 'POSTs to #incoming_sms' do
    context 'with incorrect signature' do
      it 'returns a forbidden response' do
        page.driver.post '/incoming/sms', twilio_new_message_params
        expect(page).to have_http_status(:forbidden)
      end
    end

    context 'with correct signature' do
      it 'returns a no content response' do
        twilio_post_sms(twilio_new_message_params(to_number: phone_number))
        expect(page).to have_http_status(:no_content)
      end
    end
  end
end
