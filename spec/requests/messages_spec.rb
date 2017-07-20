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

      context 'there are scheduled messages' do
        it 'does not show scheduled messages in the main timeline' do
          message = create :message, user: user, client: client, send_at: Time.now.tomorrow

          get client_messages_path(client)
          expect(response.body).to_not include(message.body)
        end

        it 'shows messages after their send_at date' do
          message = create :message, user: user, client: client, send_at: Time.now.yesterday

          get client_messages_path(client)
          expect(response.body).to include(message.body)
        end

        it 'shows no link when scheduled messages do not exist' do
          get client_messages_path(client)
          expect(response.body).not_to match(/message[s]? scheduled/)
        end

        it 'shows a link when scheduled messages exist' do
          message = create :message, user: user, client: client, send_at: Time.now.tomorrow
          message = create :message, user: user, client: client, send_at: Time.now.tomorrow

          get client_messages_path(client)
          expect(response.body).to include('2 messages scheduled')
        end
      end
    end

    describe 'POST#create' do
      it 'creates a new message on submit' do
        ActiveJob::Base.queue_adapter = :test

        body = SecureRandom.hex(4)
        message = create_message(
          build(:message, user: user, client: client, body: body)
        )
        expect(ScheduledMessageJob).to have_been_enqueued

        expect(client.messages.last.id).to eq message.id
        expect_most_recent_analytics_event({
          'message_send' => {
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

          message = create_message(
            build(:message, user: user, client: client, body: body, send_at: time_to_send)
          )
          expect(ScheduledMessageJob).to have_been_enqueued.at(time_to_send)
          expect(NotificationBroadcastJob).to have_been_enqueued.with(
            channel_id: user.id,
            text: 'Your message has been scheduled',
            link_to: '#',
            properties: nil
          )

          expect(client.messages.last.id).to eq message.id
          expect_most_recent_analytics_event({
            'message_schedule' => {
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
