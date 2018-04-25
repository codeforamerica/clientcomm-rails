require 'rails_helper'

describe 'Twilio controller', type: :request, active_job: true do
  let(:phone_number) { '+15552345678' }
  let(:has_unread_messages) { false }
  let(:has_message_error) { false }
  let(:active) { true }
  let(:dept_phone_number) { '+14242424242' }
  let(:department) { create :department, phone_number: dept_phone_number }
  let(:user) { create :user, department: department }
  let!(:client) do
    create(
      :client,
      users: [user],
      phone_number: phone_number,
      has_message_error: has_message_error,
      has_unread_messages: has_unread_messages,
      active: active
    )
  end

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

      message = Message.find_by(twilio_sid: sms_sid)
      expect(MessageBroadcastJob).to have_been_enqueued.with(message: message)
    end

    it 'enqueues a MessageRedactionJob' do
      subject

      message = Message.find_by(twilio_sid: sms_sid)
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

        rr = client.reporting_relationships.find_by(user: user)
        expect(rr.last_contacted_at).to be_within(1.second).of some_date
        expect(rr.has_unread_messages).to eq true
        expect(rr.has_message_error).to eq false
      end
    end

    context 'the client has no active relationships with a user' do
      let(:department_users) { create_list :user, 3, department: department }

      before do
        travel_to 1.day.ago do
          rr = client.reporting_relationships.find_by(user: user)
          rr.update!(active: false)

          department_users.each do |du|
            ReportingRelationship.create(user: du, client: client, active: false)
          end
        end

        ReportingRelationship.find_by(client: client, user: department_users.second)
                             .update(updated_at: Time.zone.now)
      end

      it 'reactivates the most recently active relationship' do
        subject

        rr = client.reporting_relationships.find_by(user: department_users.second)
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

    context 'the most recently active relationship is with an inactive user' do
      let(:user1) { create :user, department: department }
      let(:user2) { create :user, department: department, active: false }
      let(:client) { create :client, phone_number: phone_number }

      before do
        travel_to 1.day.ago do
          ReportingRelationship.create(user: user1, client: client, active: false)
        end

        ReportingRelationship.create(user: user2, client: client, active: false)
      end

      it 'reactivates the most recently active relationship with an active user' do
        subject
        rr = ReportingRelationship.find_by(user: user1, client: client)
        expect(rr.active).to eq true
      end
    end

    context 'the client has no relationships with an active user' do
      let(:unclaimed_user) { create :user, full_name: 'Unclaimed User', department: department }
      let(:user1) { create :user, department: department, active: false }
      let(:user2) { create :user, department: department, active: false }
      let(:client) { create :client, phone_number: phone_number }

      before do
        department.unclaimed_user = unclaimed_user
        department.save

        ReportingRelationship.create(user: user1, client: client, active: false)
        ReportingRelationship.create(user: user2, client: client, active: false)
      end

      it 'reactivates the most recently active relationship with an active user' do
        subject

        expect(unclaimed_user.clients).to include client
      end
    end

    context 'the client has no relationships within the department' do
      let(:unclaimed_user) { create :user, full_name: 'Unclaimed User', department: department }
      let(:client) { create :client, phone_number: phone_number }

      before do
        department.unclaimed_user = unclaimed_user
        department.save
        create_list :user, 3, department: department
      end

      it 'creates a relation with the unclaimed user in that department' do
        subject

        expect(unclaimed_user.clients).to include client
      end

      context 'the client does not exist at all' do
        let(:message_params) do
          twilio_new_message_params(
            from_number: '+15556667777',
            to_number: dept_phone_number,
            msg_txt: message_text,
            sms_sid: sms_sid
          )
        end

        it 'assigns the client to the unclaimed user' do
          subject

          unclaimed_client = Client.find_by(phone_number: '+15556667777')
          expect(unclaimed_client).to_not be_nil
          expect(unclaimed_user.clients).to include unclaimed_client
        end
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
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let!(:msgone) do
      create :message, reporting_relationship: rr, inbound: false, twilio_status: 'queued'
    end
    let(:sms_sid) { msgone.twilio_sid }

    subject do
      status_params = twilio_status_update_params to_number: phone_number, sms_sid: sms_sid, sms_status: sms_status
      twilio_post_sms_status status_params
    end

    context 'message received' do
      let(:sms_status) { 'received' }

      it 'saves a successful sms message status update' do
        subject
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
        subject
        expect(client.has_message_error(user: user)).to be_falsey
      end
    end

    context 'message failed' do
      let(:sms_status) { 'failed' }

      it 'saves an unsuccessful sms message status update' do
        subject
        # validate the updated status
        expect(client.messages.last.twilio_status).to eq 'failed'

        # failed analytics event
        expect_analytics_events({
                                  'message_send_failed' => {
                                    'client_id' => client.id,
                                    'message_id' => msgone.id,
                                    'message_length' => msgone.body.length,
                                    'attachments_count' => 0
                                  }
                                })

        expect_analytics_events_with_keys(
          {
            'message_send_failed' => ['message_date_scheduled', 'message_date_created']
          }
        )
      end

      it 'sets error true on associated client' do
        subject
        expect(client.has_message_error(user: user)).to be_truthy
      end
    end

    context 'message not saved yet' do
      let(:sms_sid) { 'invalid' }
      let(:sms_status) { 'sent' }

      it 'fails silently' do
        subject
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
        twilio_post_voice('To' => dept_phone_number)
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
      let(:unclaimed_number) { Faker::PhoneNumber.unique.cell_phone }
      let!(:unclaimed_user) { create :user, phone_number: unclaimed_number }
      let!(:department) { create :department, phone_number: dept_phone_number, unclaimed_user: unclaimed_user }

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
      let(:unclaimed_number) { Faker::PhoneNumber.unique.cell_phone }
      let!(:unclaimed_user) { create :user, phone_number: unclaimed_number }
      let!(:department) { create :department, phone_number: dept_phone_number, unclaimed_user: unclaimed_user }
      let!(:user) { create :user, phone_number: '', department: department }
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
      let(:unclaimed_user) { create :user, department: department }
      let!(:department) { create :department, phone_number: dept_phone_number }
      let!(:client) { create :client, user: unclaimed_user, phone_number: '+12425551212' }

      before do
        department.update!(unclaimed_user: unclaimed_user)
      end

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
