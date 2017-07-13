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
        ActiveJob::Base.queue_adapter = :test

        user = create :user
        sign_in user
        clientone = create_client build(:client)

        # send a message that's not successfully sent
        # TODO move this functionality test into ScheduledMessageJob_spec
        FakeTwilioClient.force_status = 'undelivered'
        bodyone = SecureRandom.hex(4)
        messageone = nil
        expect do
          messageone = create_message(
            build(:message, user: user, client: clientone, body: bodyone)
          )
        end.to have_enqueued_job(ScheduledMessageJob)

        expect(clientone.messages.last.id).to eq messageone.id
        expect_analytics_events_happened('message_sent_immediately')

        # send a message that's successfully sent
        bodytwo = SecureRandom.hex(4)

        messagetwo = nil
        expect do
          messagetwo = create_message(
            build(:message, user: user, client: clientone, body: bodytwo)
          )
        end.to have_enqueued_job(ScheduledMessageJob)

        expect(clientone.messages.last.id).to eq messagetwo.id
        expect_most_recent_analytics_event({
          'message_sent_immediately' => {
            'client_id' => clientone.id,
            'message_id' => messagetwo.id,
            'message_length' => messagetwo.body.length
          }
        })
      end

      context 'user sends a scheduled message' do
        let(:time_to_send) { Time.now.tomorrow.change(sec: 0) }

        it 'creates a Scheduled Message' do
          ActiveJob::Base.queue_adapter = :test

          user = create :user
          sign_in user
          clientone = create_client build(:client)

          # send a message that's successfully sent
          bodytwo = SecureRandom.hex(4)

          messagetwo = nil
          expect do
            messagetwo = create_message(
              build(:message, user: user, client: clientone, body: bodytwo, send_date: time_to_send)
            )
          end.to have_enqueued_job(ScheduledMessageJob).at(time_to_send)

          expect(clientone.messages.last.id).to eq messagetwo.id
        end
      end
    end
  end
end
