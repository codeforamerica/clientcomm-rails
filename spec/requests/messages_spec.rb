require 'rails_helper'

describe 'Messages', type: :request do
  context 'GET#index' do
    it 'marks all messages read when index loaded' do
      user = create :user
      sign_in user
      client = create_client build(:client, user: user)
      message = create :message, user: user, client: client, inbound: true

      # when we visit the messages path, it should mark the message read
      expect { get client_messages_path(client) }
        .to change { message.reload.read? }
        .from(false)
        .to(true)
    end
  end

  context 'POST#create' do
    it 'creates a new message on submit' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)

      # send a message that's not successfully sent
      FakeTwilioClient.force_status = 'undelivered'
      body1 = SecureRandom.hex(4)
      messageone = create_message(
        build(:message, user: user, client: clientone, body: body1)
      )

      expect(clientone.messages.last.id).to eq messageone.id
      expect_analytics_events_happened('message_send_failed')
      expect_analytics_events_not_happened('message_send')

      # send a message that's successfully sent
      body2 = SecureRandom.hex(4)
      messagetwo = create_message(
        build(:message, user: user, client: clientone, body: body2)
      )

      expect(clientone.messages.last.id).to eq messagetwo.id
      expect_analytics_events({
        'message_send' => {
          'client_id' => clientone.id,
          'message_id' => messagetwo.id,
          'message_length' => messagetwo.body.length
        }
      })
    end
  end
end
