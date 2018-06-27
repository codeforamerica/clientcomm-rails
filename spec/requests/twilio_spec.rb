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

    it 'enqueues an Incoming Message job' do
      subject
      expected_params = {
        From: message_params[:From],
        To: message_params[:To],
        SmsSid: message_params[:SmsSid],
        SmsStatus: message_params[:SmsStatus],
        Body: message_params[:Body],
        NumMedia: message_params[:NumMedia]
      }

      expect(IncomingMessageJob).to have_been_enqueued.with(params: expected_params)
    end

    context 'there are media URLs' do
      let(:message_params) do
        twilio_new_message_params(
          from_number: phone_number,
          to_number: dept_phone_number,
          msg_txt: message_text,
          sms_sid: sms_sid
        ).merge(
          NumMedia: 2,
          MediaUrl0: 'http://cats.com/fluffy_cat.png',
          MediaUrl1: 'http://cats.com/fluffy_cat.png',
          MediaContentType0: 'text/png',
          MediaContentType1: 'text/png'
        )
      end

      it 'enqueues an Incoming Message job with media URLs' do
        subject

        expected_params = {
          From: message_params[:From],
          To: message_params[:To],
          SmsSid: message_params[:SmsSid],
          SmsStatus: message_params[:SmsStatus],
          Body: message_params[:Body],
          NumMedia: message_params[:NumMedia].to_s,
          MediaUrl0: 'http://cats.com/fluffy_cat.png',
          MediaUrl1: 'http://cats.com/fluffy_cat.png',
          MediaContentType0: 'text/png',
          MediaContentType1: 'text/png'
        }
        expect(IncomingMessageJob).to have_been_enqueued.with(params: expected_params)
      end
    end
  end

  context 'POST#incoming_sms_status' do
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let!(:msgone) do
      create :text_message, reporting_relationship: rr, inbound: false, twilio_status: 'queued'
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
        expect_analytics_events(
          'message_send_failed' => {
            'client_id' => client.id,
            'message_id' => msgone.id,
            'message_length' => msgone.body.length,
            'attachments_count' => 0
          }
        )

        expect_analytics_events_with_keys(
          'message_send_failed' => ['message_date_scheduled', 'message_date_created']
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
          'phonecall_receive' => {
            'client_id' => 'no client',
            'client_identified' => false,
            'call_routed' => false,
            'has_desk_phone' => false
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
          'phonecall_receive' => {
            'client_id' => 'no client',
            'client_identified' => false,
            'call_routed' => true,
            'has_desk_phone' => false
          }
        )
      end
    end

    context 'client has only an inactive relationship' do
      let!(:user) { create :user, phone_number: '+19999999999', dept_phone_number: dept_phone_number }
      let!(:client) { create :client, user: user, phone_number: '+12425551212' }

      before do
        ReportingRelationship.find_by(user: user, client: client).update!(active: false)
      end

      it 'responds with text-only message' do
        twilio_post_voice('To' => dept_phone_number)
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/xml'
        expect(response.body).to include 'This phone number can only receive text messages. Please hang up and send a text message.'

        expect_analytics_events(
          'phonecall_receive' => {
            'client_id' => client.id,
            'client_identified' => false,
            'call_routed' => false,
            'has_desk_phone' => false
          }
        )
      end

      context 'a department phone number is set' do
        let(:unclaimed_number) { Faker::PhoneNumber.unique.cell_phone }
        let!(:unclaimed_user) { create :user, phone_number: unclaimed_number }
        let!(:department) { Department.find_by(phone_number: dept_phone_number) }

        before do
          department.update!(user_id: unclaimed_user.id)
        end

        it 'responds with xml that connects the call to the unclaimed user' do
          twilio_post_voice('To' => dept_phone_number)
          expect(response.status).to eq 200
          expect(response.content_type).to eq 'application/xml'
          expect(response.body).to include "<Number>#{unclaimed_number}</Number>"
          expect_analytics_events(
            'phonecall_receive' => {
              'client_id' => client.id,
              'client_identified' => false,
              'call_routed' => true,
              'has_desk_phone' => false
            }
          )
        end
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
          'phonecall_receive' => {
            'client_id' => client.id,
            'client_identified' => true,
            'call_routed' => true,
            'has_desk_phone' => false
          }
        )
      end

      context 'admin phone number not set' do
        let(:unclaimed_number) { nil }

        it_behaves_like 'valid xml response'
        it 'sends the correct analytics event' do
          twilio_post_voice('To' => dept_phone_number)
          expect_analytics_events(
            'phonecall_receive' => {
              'client_id' => client.id,
              'client_identified' => true,
              'call_routed' => false,
              'has_desk_phone' => false
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
          'phonecall_receive' => {
            'client_id' => client.id,
            'client_identified' => true,
            'call_routed' => true,
            'has_desk_phone' => true
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
          'phonecall_receive' => {
            'client_id' => client.id,
            'client_identified' => false,
            'call_routed' => true,
            'has_desk_phone' => true
          }
        )
      end
    end
  end
end
