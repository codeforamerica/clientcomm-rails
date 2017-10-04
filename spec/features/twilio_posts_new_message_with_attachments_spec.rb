require 'rails_helper'

feature 'Twilio' do
  after do
    page.driver.header 'X-Twilio-Signature', nil
  end

  describe 'POSTs to #incoming_sms' do
    context 'with legacy_attachments' do
      before do
        stub_request(:get, 'http://cats.com/fluffy_cat.png').
            to_return(status: 200,
                      body: File.read('spec/fixtures/fluffy_cat.jpg'),
                      headers: {'Accept-Ranges' => 'bytes', 'Content-Length' => '4379330', 'Content-Type' => 'image/jpeg'})
      end

      it 'displays the legacy_attachments on the page' do
        user = create :user
        login_as(user, :scope => :user)
        twilio_params = twilio_new_message_params(msg_txt: '').merge(NumMedia: 1, MediaUrl0: 'http://cats.com/fluffy_cat.png', MediaContentType0: 'image/jpeg')
        client = create :client, user: user, phone_number: twilio_params['From']
        twilio_post_sms twilio_params
        expect(page).to have_http_status(:no_content)
        visit client_messages_path client
        expect(find('.message--inbound img')[:src]).to include 'fluffy_cat.png'
      end
    end
  end
end
