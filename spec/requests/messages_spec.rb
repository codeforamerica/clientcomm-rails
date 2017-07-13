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
    let(:client) { create_client build(:client, user: user) }

    before do
      sign_in user
    end

    describe 'GET#index' do
      it 'marks all messages read when index loaded' do
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

        body = SecureRandom.hex(4)
        message = nil
        expect do
          message = create_message(
            build(:message, user: user, client: client, body: body)
          )
        end.to have_enqueued_job(ScheduledMessageJob)

        expect(client.messages.last.id).to eq message.id
        expect_most_recent_analytics_event({
          'message_sent_immediately' => {
            'client_id' => client.id,
            'message_id' => message.id,
            'message_length' => message.body.length
          }
        })
      end

      context 'user sends a scheduled message' do
        let(:time_to_send) { Time.now.tomorrow.change(sec: 0) }

        it 'creates a Scheduled Message' do
          ActiveJob::Base.queue_adapter = :test

          # send a message that's successfully sent
          message = nil
          expect do
            message = create_message(
              build(:message, user: user, client: client, body: body, send_date: time_to_send)
            )
          end.to have_enqueued_job(ScheduledMessageJob).at(time_to_send)

          expect(client.messages.last.id).to eq message.id
          expect_most_recent_analytics_event({
            'message_scheduled' => {
              'client_id' => client.id,
              'message_id' => message.id,
              'message_length' => message.body.length,
              'scheduled_for' => time_to_send
            }
          })
        end
      end
    end
  end
end
