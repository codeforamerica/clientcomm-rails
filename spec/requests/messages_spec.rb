require 'rails_helper'

describe 'Messages requests', type: :request, active_job: true do
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
    let(:body) { 'hello, my friend' }

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

    describe 'DELETE#destroy' do
      context 'there are scheduled messages' do
        it 'deletes a scheduled message' do
          message = create :message, user: user, client: client, send_at: Time.now.tomorrow

          delete message_path(message)

          expect(response.code).to eq '302'
          expect(response).to redirect_to client_messages_path(client)

          get client_messages_path(client)
          expect(response.body).to_not include('1 message scheduled')

          expect_analytics_events_happened('message_scheduled_delete')
        end
      end
    end

    describe 'GET#edit' do
      it 'renders the requested message template' do
        message = create :message, user: user, client: client, inbound: true, send_at:  Time.zone.local(2012, 07, 11, 20, 30, 0)

        get edit_message_path(message)

        expect(response.body).to include(message.body)
        expect(response.body).to include('07/11/2012')

        expect_analytics_events_happened('message_scheduled_edit_view')
      end
    end

    describe 'POST#create' do
      let(:post_params) {
        {
            message: {body: body, send_at: message_send_at},
            client_id: client.id
        }
      }

      context 'no date' do
        let(:message_send_at) { nil }

        it 'creates a new message on submit' do
          post messages_path, params: post_params

          message = Message.find_by(body: body)

          expect(ScheduledMessageJob).to have_been_enqueued
          created_message = client.messages.last

          expect(created_message.id).to eq message.id
          expect(created_message.read).to eq true
          expect(created_message.send_at).to_not be_nil

          expect_most_recent_analytics_event(
              {
                  'message_send' => {
                      'client_id' => client.id,
                      'message_id' => message.id,
                      'message_length' => body.length
                  }
              }
          )
        end
      end

      context 'invalid date' do
        let(:message_send_at) {
          {
              date: 'foo',
              time: 'bar'
          }
        }

        it 'does not create a new message' do
          post messages_path, params: post_params

          expect(ScheduledMessageJob).not_to have_been_enqueued
        end
      end

      context 'valid date' do
        let(:time_to_send) {Time.now.tomorrow.change(sec: 0)}
        let(:message_send_at) {
          {
              date: time_to_send.strftime("%m/%d/%Y"),
              time: time_to_send.strftime("%-l:%M%P")
          }
        }

        it 'creates a Scheduled Message' do
          post messages_path, params: post_params

          message = Message.find_by(body: body)
          expect(ScheduledMessageJob).to have_been_enqueued.at(time_to_send)
          expect(flash[:notice]).to eq('Your message has been scheduled')

          expect(client.messages.last.id).to eq message.id
          expect_analytics_events_with_keys(
              {
                  'message_scheduled' => [
                    'client_id',
                    'message_id',
                    'message_length',
                    'message_date_scheduled',
                    'message_date_created'
                  ]
              })
        end
      end
    end

    describe 'PUT#update' do
      let(:time_to_send) { Time.now.tomorrow.change(sec: 0) }

      it 'updates the message model' do
        message = build(:message, user: user, client: client, body: body, send_at: time_to_send)
        post_params = {
            message: {
                body: body,
                send_at: {
                    'date': message.send_at.strftime("%m/%d/%Y"),
                    'time': message.send_at.strftime("%-l:%M%P")
                }
            },
            client_id: client.id
        }

        post messages_path, params: post_params
        message = Message.find_by(body: message.body)
        expect(ScheduledMessageJob).to have_been_enqueued.at(time_to_send)

        new_time_to_send = Time.now.change(sec: 0)
        message.send_at = new_time_to_send
        message.body = "Some new body"
        old_message_id = message.id

        update_message(message)
        expect(ScheduledMessageJob).to have_been_enqueued.at(new_time_to_send)

        new_message = Message.find(old_message_id)

        expect(new_message.body).to eq("Some new body")
        expect(new_message.send_at).to eq(new_time_to_send)
      end
    end

    describe 'GET#download' do
      it 'downloads messages as a text file' do
        messages = create_list :message, 10, user: user, client: client

        get client_messages_download_path(client)

        messages.each do |message|
          expect(response.body).to include(message.number_from) if message.inbound
          expect(response.body).to include(message.number_to) unless message.inbound
          expect(response.body).to include(message.created_at.strftime("%b %-d %Y, %-l:%M:%S %P"))
          expect(response.body).to include(message.body)
          expect(response.body).to include(client.first_name)
          expect(response.body).to include(user.full_name)
        end
      end
    end
  end

end
