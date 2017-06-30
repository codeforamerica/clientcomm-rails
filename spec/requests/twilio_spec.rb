require 'rails_helper'

describe 'Twilio controller', type: :request do
  context 'POST#incoming_sms' do
    it 'saves an incoming sms message' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      # post a new message
      message_text = 'Hello, this is a new message from a client!'
      message_params = twilio_new_message_params(
        from_number: clientone.phone_number, msg_txt: message_text
      )
      twilio_post_sms message_params
      msg = user.messages.last
      expect(msg).not_to eq nil
      expect(msg.body).to eq message_text
    end
  end

  context 'POST#incoming_sms_status' do
    it 'saves a successful sms message status update' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      msgone = create :message, user: user, client: clientone, inbound: true, twilio_status: 'queued'
      # validate the status
      expect(clientone.messages.last.twilio_status).to eq 'queued'

      # post a status update
      status_params = twilio_status_update_params from_number: clientone.phone_number, sms_sid: msgone.twilio_sid, sms_status: 'received'
      twilio_post_sms_status status_params

      # validate the updated status
      expect(clientone.messages.last.twilio_status).to eq 'received'

      # no failed analytics event
      expect_analytics_events_not_happened('message_send_failed')
    end
  end

  context 'POST#incoming_sms_status' do
    it 'saves an unsuccessful sms message status update' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      msgone = create :message, user: user, client: clientone, inbound: true, twilio_status: 'queued'
      # validate the status
      expect(clientone.messages.last.twilio_status).to eq 'queued'

      # post a status update
      status_params = twilio_status_update_params from_number: clientone.phone_number, sms_sid: msgone.twilio_sid, sms_status: 'failed'
      twilio_post_sms_status status_params

      # validate the updated status
      expect(clientone.messages.last.twilio_status).to eq 'failed'

      # failed analytics event
      expect_analytics_events_happened('message_send_failed')
    end
  end
end

