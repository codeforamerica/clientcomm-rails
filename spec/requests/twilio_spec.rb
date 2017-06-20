require 'rails_helper'

describe 'Twilio controller', type: :request do
  context 'POST#incoming_sms' do
    it 'receives an incoming sms message' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      # post a new message
      message_text = 'Hello, this is a new message from a client!'
      message_params = twilio_new_message_params(
        clientone.phone_number, nil, message_text
      )
      twilio_post_sms message_params
      msg = user.messages.last
      expect(msg).not_to eq nil
      expect(msg.body).to eq message_text
    end
  end
end

