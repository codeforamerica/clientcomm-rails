require 'rails_helper'

feature 'Twilio' do
  let(:message_params) { twilio_new_message_params }
  let(:status_params) { twilio_status_update_params from_number: message_params['From'], sms_sid: message_params['SmsSid'] }

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
        twilio_post_sms_status status_params, false
        expect(page).to have_http_status(:forbidden)
      end
    end

    context 'with correct signature' do
      it 'returns a no content response' do
        twilio_post_sms_status status_params
        expect(page).to have_http_status(:no_content)
      end
    end

    context 'many requests at once', :js do
      let(:user) { create :user }
      let(:client) { create :client, user: user }

      before do
        visit root_path
      end

      it 'handles it' do
        message = create :message, client: client, user: user, inbound: false, twilio_status: 'queued'

        threads = %w[first second third fourth].each_with_index.map do |status, i|
          Thread.new do
            status_params = twilio_status_update_params(
              to_number: message.number_to,
              sms_sid: message.twilio_sid,
              sms_status: status
            )
            twilio_post_sms_status status_params, true, 'X-Request-Start' => "151752434924#{i}"
          end
        end

        threads.map(&:join)

        expect(message.reload.twilio_status).to eq 'fourth'
      end
    end
  end
end
