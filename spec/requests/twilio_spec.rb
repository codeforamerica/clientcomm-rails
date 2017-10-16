require 'rails_helper'

describe 'Twilio controller', type: :request, active_job: true do
  let(:phone_number) { '+15552345678' }
  let(:has_unread_messages) { false }
  let(:has_message_error) { false }
  let(:active) { true }
  let(:user) { create :user }
  let!(:client) { create :client, user:user, phone_number: phone_number, has_message_error: has_message_error, has_unread_messages: has_unread_messages, active: active }

  context 'POST#incoming_sms' do
    let(:message_text) { 'Hello, this is a new message from a client!' }
    let(:sms_sid) { Faker::Crypto.sha1 }
    let(:message_params) {
      twilio_new_message_params(
          from_number: phone_number,
          msg_txt: message_text,
          sms_sid: sms_sid
      )
    }

    subject do
      twilio_post_sms message_params
    end

    it 'saves an incoming sms message' do
      subject

      msg = client.messages.last
      expect(msg.body).to eq message_text
    end

    it 'tracks an incoming sms message' do
      subject

      expect_analytics_events(
          {
              'message_receive' => {
                  'client_id' => client.id,
                  'message_length' => message_text.length,
                  'attachments_count' => 0,
                  'client_active' => true
              }
          }
      )
    end

    it 'sends an email notification to user' do
      perform_enqueued_jobs { subject }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.html_part.to_s).to include 'sent you a text message'
    end

    it 'enqueues a MessageBroadcastJob' do
      subject

      message = Message.find_by_twilio_sid(sms_sid)
      expect(MessageBroadcastJob).to have_been_enqueued.with(message: message)
    end

    it 'enqueues a MessageRedactionJob' do
      subject

      message = Message.find_by_twilio_sid(sms_sid)
      expect(MessageRedactionJob).to have_been_enqueued.with(message: message)
    end

    it 'enqueues a NotificationBroadcastJob' do
      subject

      expect(NotificationBroadcastJob).to have_been_enqueued.with(
        channel_id: user.id,
        properties: { client_id: client.id },
        link_to: String,
        text: String
      )
    end

    context 'client has message error and no unread messages' do
      let(:has_unread_messages) { false }
      let(:has_message_error) { true }

      it 'updates the client last_contacted_at, has_unread_messages, has_message_error' do
        some_date = rand(10.years).seconds.ago

        travel_to some_date do
          subject
        end

        client.reload

        expect(client.last_contacted_at).to be_within(1.seconds).of some_date
        expect(client.has_unread_messages).to eq true
        expect(client.has_message_error).to eq false
      end
    end

    context 'the client was previously inactive' do
      let(:active) { false }

      it 'returns the client to the active list' do
        subject

        expect(client.reload.active).to eq true
      end

      it 'tracks that the client was previously inactive' do
        subject

        expect_analytics_events(
            {
                'message_receive' => {
                    'client_id' => client.id,
                    'message_length' => message_text.length,
                    'attachments_count' => 0,
                    'client_active' => false
                }
            }
        )
      end
    end

    context 'a user has opted out of emails' do
      before do
        client.user.update!(email_subscribe: false)
      end

      it 'should not send an email' do
        expect(NotificationMailer).to_not receive(:message_notification)

        subject
      end
    end

    context 'sms message contains an attachment' do
      let(:message_params) do
        twilio_new_message_params(
            from_number: phone_number,
            msg_txt: message_text
        ).merge(NumMedia: 1, MediaUrl0: 'http://cats.com/fluffy_cat.png', MediaContentType0: 'text/png')
      end

      before do
        stub_request(:get, 'http://cats.com/fluffy_cat.png').
            to_return(status: 200,
                      body: File.read('spec/fixtures/fluffy_cat.jpg'),
                      headers: {'Accept-Ranges'=>'bytes', 'Content-Length'=>'4379330', 'Content-Type'=>'image/jpeg'})
      end

      it 'attaches the image to the message' do
        subject

        message = Message.last

        expect(message.attachments.length).to eq(1)
        expect(message.attachments.first.media.exists?).to eq(true)
      end

      it 'tracks an analytics event for the attachment' do
        subject

        expect_analytics_events(
            {
                'message_receive' => {
                    'client_id' => client.id,
                    'message_length' => message_text.length,
                    'attachments_count' => 1
                }
            }
        )
      end
    end
  end

  context 'POST#incoming_sms_status' do
    let!(:msgone) {
      create :message, client: client, inbound: false, twilio_status: 'queued'
    }
    let(:sms_sid) { msgone.twilio_sid }

    before do
      allow(SMSService.instance).to receive(:redact_message)

      subject
    end

    subject {
      status_params = twilio_status_update_params to_number: phone_number, sms_sid: sms_sid, sms_status: sms_status
      twilio_post_sms_status status_params
    }

    context 'message received' do
      let(:sms_status) { 'received' }

      it 'saves a successful sms message status update' do
        # validate the updated status
        expect(client.messages.last.twilio_status).to eq 'received'

        # no failed analytics event
        expect_analytics_events_not_happened('message_send_failed')

        expect(response.code).to eq '204'
      end
    end

    context 'message delivered' do
      let(:sms_status) { 'delivered' }

      it 'associated client has false message error' do
        expect(client.reload.has_message_error).to be_falsey
      end

      it 'redacts the message' do
        expect(SMSService.instance).to have_received(:redact_message).with(message: msgone)
      end
    end

    context 'message failed' do
      let(:sms_status) { 'failed' }

      it 'saves an unsuccessful sms message status update' do
        # validate the updated status
        expect(client.messages.last.twilio_status).to eq 'failed'

        # failed analytics event
        expect_analytics_events({
          'message_send_failed' => {
            'client_id' => client.id,
            'message_id' => msgone.id,
            'message_length' => msgone.body.length,
            'attachments_count' => 0,
          }
        })

        expect_analytics_events_with_keys(
          {
            'message_send_failed' => ['message_date_scheduled', 'message_date_created']
          }
        )
      end

      it 'sets error true on associated client' do
        expect(client.reload.has_message_error).to be_truthy
      end

      it 'redacts the message' do
        expect(SMSService.instance).to have_received(:redact_message).with(message: msgone)
      end
    end

    context 'message not saved yet' do
      let(:sms_sid) { 'invalid' }
      let(:sms_status) { 'sent' }

      it 'fails silently' do
        expect(client.messages.last.twilio_status).to eq 'queued'
        expect(response.code).to eq '204'
      end
    end
  end

  context 'POST#incoming_voice' do

    shared_examples 'valid xml response' do
      it 'responds with xml' do
        twilio_post_voice()
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/xml'
        expect(response.body).to include 'This phone number can only receive text messages. Please hang up and send a text message.'
      end
    end

    context 'defaults to reading a message' do
      it_behaves_like 'valid xml response'
    end

    context 'client is in a user case load but user does not have a desk phone' do
      let!(:user) { create :user, phone_number: '' }
      let!(:client) { create :client, user: user, phone_number: '+12425551212' }

      it_behaves_like 'valid xml response'
    end

    context 'client is not associated with a user' do
      let!(:client) { create :client, user: nil, phone_number: '+12425551212' }

      it_behaves_like 'valid xml response'
    end

    context 'client is in a user case load' do
      let!(:user) { create :user, phone_number: '+19999999999' }
      let!(:client) { create :client, user: user, phone_number: '+12425551212' }

      it 'responds with xml that connects the call' do
        twilio_post_voice()
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/xml'
        expect(response.body).to include '<Number>+19999999999</Number>'
      end
    end

  end
end
