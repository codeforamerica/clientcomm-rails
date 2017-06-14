require 'rails_helper'

describe 'Tracking of twilio analytics events', type: :request do
  context 'POST#incoming_sms' do
    it 'tracks an incoming sms message' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      # post a new message
      message_text = 'Hello, this is a new message from a client!'
      message_params = twilio_new_message_params(
        clientone.phone_number, nil, message_text
      )
      twilio_post_sms message_params
      # validate the analytics event
      expect_analytics_events({
        'message_receive' => {
          'client_id' => clientone.id,
          'message_length' => message_text.length
        }
      })
    end
  end
end
