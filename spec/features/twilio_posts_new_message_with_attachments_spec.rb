require 'rails_helper'

feature 'Twilio' do
  after do
    page.driver.header 'X-Twilio-Signature', nil
  end

  describe 'POSTs to #incoming_sms' do
    context 'with attachments' do
      it 'displays the attachments on the page' do
        user = create :user
        login_as(user, :scope => :user)
        twilio_params = twilio_new_message_params media_count: 1
        client = create :client, user: user, phone_number: twilio_params['From']
        twilio_post_sms twilio_params
        expect(page).to have_http_status(:no_content)
        visit client_messages_path client
        expect(page).to have_css %Q|.message--inbound img[src="#{twilio_params['MediaUrl0']}"]|
      end
    end
  end
end
