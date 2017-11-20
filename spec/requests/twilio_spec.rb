require 'rails_helper'

describe 'Twilio controller', type: :request, active_job: true do
  let(:phone_number) { '+15552345678' }
  let(:has_unread_messages) { false }
  let(:has_message_error) { false }
  let(:active) { true }
  let(:dept_phone_number) { '+14242424242' }
  let(:user) { create :user, dept_phone_number: dept_phone_number }
  let!(:client) {
    create(
      :client,
      user: user,
      phone_number: phone_number,
      has_message_error: has_message_error,
      has_unread_messages: has_unread_messages,
      active: active
    )
  }

  context 'POST#incoming_sms' do
    let(:message_text) { 'Hello, this is a new message from a client!' }
    let(:sms_sid) { Faker::Crypto.sha1 }
    let(:message_params) {
      twilio_new_message_params(
        from_number: phone_number,
        to_number: dept_phone_number,
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
      before do
        rr = client.reporting_relationships.find_by(user: user)
        rr.update!(active: false)
      end

      it 'returns the client to the active list' do
        subject

        rr = client.reporting_relationships.find_by(user: user)
        expect(rr.active).to eq true
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
        user.update!(message_notification_emails: false)
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
          to_number: dept_phone_number,
          msg_txt: message_text
        ).merge(NumMedia: 1, MediaUrl0: 'http://cats.com/fluffy_cat.png', MediaContentType0: 'text/png')
      end

      before do
        stub_request(:get, 'http://cats.com/fluffy_cat.png')
          .to_return(status: 200,
                     body: File.read('spec/fixtures/fluffy_cat.jpg'),
                     headers: {
                       'Accept-Ranges' => 'bytes',
                       'Content-Length' => '4379330',
                       'Content-Type' => 'image/jpeg'
                     })
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
        twilio_post_voice('To' => dept_phone_number)
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/xml'
        expect(response.body).to include 'This phone number can only receive text messages. Please hang up and send a text message.'
      end
    end

    context 'defaults to reading a message' do
      it_behaves_like 'valid xml response'
      it 'sends the correct analytics event' do
        twilio_post_voice
        expect_analytics_events(
          {
            'phonecall_receive' => {
              'client_id' => 'no client',
              'client_identified' => false,
              'call_routed' => false,
              'has_desk_phone' => false
            }
          }
        )
      end
    end

    context 'client does not exist' do
      before do
        @old_unclaimed = ENV['UNCLAIMED_EMAIL']
        ENV['UNCLAIMED_EMAIL'] = 'unclaimed@test.com'
      end

      after do
        ENV['UNCLAIMED_EMAIL'] = @old_unclaimed
      end

      let(:unclaimed_number) { Faker::PhoneNumber.unique.cell_phone }
      let!(:unclaimed_user) { create :user, phone_number: unclaimed_number, email: ENV['UNCLAIMED_EMAIL'] }

      it 'responds with xml that connects the call to the unclaimed user' do
        twilio_post_voice('To' => dept_phone_number)
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/xml'
        expect(response.body).to include "<Number>#{unclaimed_number}</Number>"
        expect_analytics_events(
          {
            'phonecall_receive' => {
              'client_id' => 'no client',
              'client_identified' => false,
              'call_routed' => true,
              'has_desk_phone' => false
            }
          }
        )
      end
    end

    context 'client is in a user case load but user does not have a desk phone' do
      before do
        @old_unclaimed = ENV['UNCLAIMED_EMAIL']
        ENV['UNCLAIMED_EMAIL'] = 'unclaimed@test.com'
      end

      after do
        ENV['UNCLAIMED_EMAIL'] = @old_unclaimed
      end

      let(:unclaimed_number) { Faker::PhoneNumber.unique.cell_phone }
      let!(:user) { create :user, phone_number: '', dept_phone_number: dept_phone_number }
      let!(:unclaimed_user) { create :user, phone_number: unclaimed_number, email: ENV['UNCLAIMED_EMAIL'] }
      let!(:client) { create :client, user: user, phone_number: '+12425551212' }

      it 'responds with xml that connects the call to the unclaimed user' do
        twilio_post_voice('To' => dept_phone_number)
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/xml'
        expect(response.body).to include "<Number>#{unclaimed_number}</Number>"

        expect_analytics_events(
          {
            'phonecall_receive' => {
              'client_id' => client.id,
              'client_identified' => true,
              'call_routed' => true,
              'has_desk_phone' => false
            }
          }
        )
      end

      context 'admin phone number not set' do
        let(:unclaimed_number) { nil }

        it_behaves_like 'valid xml response'
        it 'sends the correct analytics event' do
          twilio_post_voice('To' => dept_phone_number)
          expect_analytics_events(
            {
              'phonecall_receive' => {
                'client_id' => client.id,
                'client_identified' => true,
                'call_routed' => false,
                'has_desk_phone' => false
              }
            }
          )
        end
      end
    end

    context 'client is in a user case load' do
      let!(:user) { create :user, phone_number: '+19999999999', dept_phone_number: dept_phone_number }
      let!(:client) { create :client, user: user, phone_number: '+12425551212' }

      it 'responds with xml that connects the call' do
        twilio_post_voice('To' => dept_phone_number)
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/xml'
        expect(response.body).to include '<Number>+19999999999</Number>'
        expect_analytics_events(
          {
            'phonecall_receive' => {
              'client_id' => client.id,
              'client_identified' => true,
              'call_routed' => true,
              'has_desk_phone' => true
            }
          }
        )
      end
    end

    context 'the client is in the unclaimed caseload' do
      let(:unclaimed_number) { Faker::PhoneNumber.unique.cell_phone }
      let(:unclaimed_user) { create :user, phone_number: unclaimed_number, email: ENV['UNCLAIMED_EMAIL'], dept_phone_number: dept_phone_number }
      let!(:client) { create :client, user: unclaimed_user, phone_number: '+12425551212' }

      it 'sends the correct analytics event' do
        twilio_post_voice('To' => dept_phone_number)
        expect_analytics_events(
          {
            'phonecall_receive' => {
              'client_id' => client.id,
              'client_identified' => false,
              'call_routed' => true,
              'has_desk_phone' => true
            }
          }
        )
      end
    end
  end
end
