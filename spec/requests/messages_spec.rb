require 'rails_helper'

describe 'Messages requests', type: :request do
  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      client = create(:client)

      get client_messages_path(client)

      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'authenticated' do
    let(:user) { create :user }

    before do
      sign_in user
    end

    describe 'GET#index' do
      it 'marks all messages read when index loaded' do
        client = create_client build(:client, user: user)
        message = create :message, user: user, client: client, inbound: true

        # when we visit the messages path, it should mark the message read
        expect { get client_messages_path(client) }
          .to change { message.reload.read? }
          .from(false)
          .to(true)
      end
    end

    describe 'POST#create' do
      it 'creates a new message on submit' do
        clientone = create_client build(:client)

        # send a message that's not successfully sent
        FakeTwilioClient.force_status = 'undelivered'
        bodyone = SecureRandom.hex(4)
        messageone = create_message(
          build(:message, user: user, client: clientone, body: bodyone)
        )

        expect(clientone.messages.last.id).to eq messageone.id
        expect_analytics_events_happened('message_send_failed')
        expect_analytics_events_not_happened('message_send')

        # send a message that's successfully sent
        bodytwo = SecureRandom.hex(4)
        messagetwo = create_message(
          build(:message, user: user, client: clientone, body: bodytwo)
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
end
