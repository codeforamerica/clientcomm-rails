require 'rails_helper'

describe 'Tracking of twilio analytics events', type: :request do
  context 'POST#incoming_sms' do
    it 'tracks an incoming sms message' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      # post a new message
      message_text = 'Hello, this is a new message from a client!'
      twilio_post_sms(
        twilio_new_message_params(
          from_number: clientone.phone_number,
          msg_txt: message_text
        )
      )
      # validate the analytics event
      expect_analytics_events({
        'message_receive' => {
          'client_id' => clientone.id,
          'message_length' => message_text.length,
          'client_existed' => true
        }
      })
    end
  end
end
