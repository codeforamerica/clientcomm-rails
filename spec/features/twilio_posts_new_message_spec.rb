require 'rails_helper'

feature 'Twilio' do
  let(:phone_number) { 'something explicit' }
  let(:department) { create :department, phone_number: phone_number }
  let(:user) { create :user, department: department }
  let(:client) { create :client, user: user, phone_number: twilio_new_message_params['From'] }
  let(:message_body) { 'some message body' }

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
        twilio_post_sms(
          twilio_new_message_params(
            to_number: phone_number,
            from_number: client.phone_number,
            msg_txt: message_body
          )
        )
        expect(page).to have_http_status(:no_content)

        login_as user, scope: :user
        rr = user.reporting_relationships.find_by(client: client)
        visit reporting_relationship_path(rr)
        expect(page).to have_content message_body
      end

      it 'allows blank messages' do
        twilio_post_sms(
          twilio_new_message_params(
            to_number: phone_number,
            from_number: client.phone_number,
            msg_txt: ''
          )
        )

        expect(page).to have_http_status(:no_content)

        login_as user, scope: :user
        rr = user.reporting_relationships.find_by(client: client)
        visit reporting_relationship_path(rr)
        expect(find("#message_#{Message.last.id} .message--content").text).to be_empty
      end
    end
  end
end
