require 'rails_helper'

RSpec.describe Message, type: :model do
  describe '#first?' do
    let(:message) { create :message, send_at: send_at }

    before do
      create :message, user: message.user, client: message.client, send_at: Time.new(2010, 1, 1, 1, 1, 2)
      create :message, user: message.user, client: message.client, send_at: Time.new(2010, 1, 1, 1, 1, 3)
      create :message, user: message.user, client: message.client, send_at: Time.new(2010, 1, 1, 1, 1, 4)
    end

    subject do
      message.first?
    end

    context 'message is first' do
      let(:send_at) { Time.new(2010, 1, 1, 1, 1, 1) }

      it 'sends analytics tracking data' do
        expect(subject).to eq true
      end
    end

    context 'message is not first' do
      let(:send_at) { Time.new(2010, 1, 1, 1, 1, 5) }

      it 'sends analytics tracking data' do
        expect(subject).to eq false
      end
    end
  end

  describe 'analytics_tracker_data' do
    let(:client_id) { 5 }
    let(:user_id) { 10 }
    let(:body_length) { 10 }
    let(:body) { Faker::Lorem.characters(body_length) }
    let(:send_at) { Time.new(2010, 1, 1, 1, 1, 1) }
    let(:created_at) { Time.new(2009, 2, 1, 1, 1, 1) }
    let(:user) { create :user, id: user_id }
    let(:client) { create :client, id: client_id, user: user }
    let(:message) do
      create(
        :message,
        client: client,
        body: body,
        user: user,
        send_at: send_at,
        created_at: created_at
      )
    end
    let(:message_id) { message.id }

    subject do
      message.analytics_tracker_data
    end

    it 'sends analytics tracking data' do
      expect(subject).to include(
        client_id: client_id,
        message_id: message_id,
        message_date_scheduled: send_at,
        message_date_created: created_at,
        message_length: body_length,
        current_user_id: user_id,
        attachments_count: 0,
        client_active: true, # Default
        first_message: true
      )
    end

    context 'there are many messages' do
      let(:send_at) { Time.new(2010, 1, 1, 1, 1, 5) }

      before do
        create :message, user: user, client: client, send_at: Time.new(2010, 1, 1, 1, 1, 2)
        create :message, user: user, client: client, send_at: Time.new(2010, 1, 1, 1, 1, 3)
        create :message, user: user, client: client, send_at: Time.new(2010, 1, 1, 1, 1, 4)
      end

      it 'sends analytics tracking data' do
        expect(subject).to include(
          first_message: false
        )
      end
    end

    context 'client is inactive' do
      let(:client) { create :client, id: client_id, user: user, active: false }

      it 'client_active is correct' do
        expect(subject).to include(client_active: false)
      end
    end

    context 'message has attachments' do
      let(:attachments_count) { 3 }

      before do
        create_list(:attachment, attachments_count, message: message)
      end

      it 'attachments count is correct' do
        expect(subject).to include(attachments_count: attachments_count)
      end
    end
  end

  describe 'relationships' do
    it { should belong_to :client }
    it { should belong_to :user }
    it { should have_many :attachments }

    it do
      should validate_presence_of(:send_at)
        .with_message("That date didn't look right.")
    end

    context 'validating body of message' do
      it 'does not validate message with empty body with no attachments' do
        m = Message.create(body: '')
        expect(m.errors[:body].present?).to eq true
      end

      it 'validates empty body with attachment' do
        m = build :message, body: ''
        m.attachments << build(:attachment)

        expect(m).to be_valid
      end

      it 'validates empty body for incoming messages' do
        m = build :message, body: '', inbound: true

        expect(m).to be_valid
      end
    end

    it 'should validate that a message is scheduled in the future' do
      expect(Message.new.past_message?).to be_falsey

      expect(Message.new(send_at: Time.current - 1.day).past_message?).to be_truthy

      expect(Message.new(send_at: Time.current).past_message?).to be_falsey
      expect(Message.new(send_at: Time.current + 5.minutes).past_message?).to be_falsey

      message = Message.new(send_at: Time.current - 1.day)
      message.past_message?
      expect(message.errors[:send_at])
        .to include "You can't schedule a message in the past."
    end

    it 'validates that a messages cannot be scheduled a year in advance' do
      expect(Message.new(send_at: Time.current + 2.years).valid?).to be_falsey
    end
  end

  describe 'accessors' do
    describe '#reporting_relationship:user' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let!(:rr) { ReportingRelationship.create(user: user, client: client) }
      let!(:message) { create :message, user: user, client: client }

      it 'returns the relevant value' do
        expect(message.reporting_relationship).to eq(rr)
      end
    end
  end

  describe '#create_from_twilio' do
    context 'client does not exist', active_job: true do
      let(:dept_phone_number) { '+17609996661' }
      let(:department) { create :department, phone_number: dept_phone_number }
      let(:unclaimed_user) { create :user, full_name: 'Unclaimed User', department: department }
      let(:autoreply_message) { 'This is the unclaimed auto-reply message.' }

      before do
        department.unclaimed_user = unclaimed_user
        department.save
        ENV['UNCLAIMED_AUTOREPLY_MESSAGE'] = autoreply_message
      end

      it 'creates a new client with missing information' do
        unknown_number = '+19999999999'
        params = twilio_new_message_params from_number: unknown_number, to_number: dept_phone_number

        message = Message.create_from_twilio!(params)

        expect(message.user).to eq unclaimed_user
        expect(message.number_to).to eq dept_phone_number
        expect(message.number_from).to eq unknown_number
        expect(message.inbound).to be_truthy
        expect(message.send_at).to be_present

        client = message.client
        expect(client.first_name).to be_nil
        expect(client.last_name).to eq unknown_number
        expect(client.phone_number).to eq unknown_number
        expect(client.users).to include unclaimed_user
      end

      it 'autoreplies to the new client' do
        unknown_number = '+19999999999'
        params = twilio_new_message_params from_number: unknown_number, to_number: dept_phone_number

        time = Time.now.change(usec: 0)
        expect {
          travel_to time do
            Message.create_from_twilio!(params)
          end
        }.to have_enqueued_job(ScheduledMessageJob)

        job_args = enqueued_jobs.first[:args].first
        message = GlobalID::Locator.locate job_args['message']['_aj_globalid']
        expect(message).to_not be_nil
        expect(message.number_from).to eq(department.phone_number)
        expect(message.number_to).to eq(unknown_number)
        expect(message.body).to eq(autoreply_message)
        expect(message.send_at).to eq(time)
        expect(job_args['send_at']).to eq(time.to_i)
        expect(job_args['callback_url']).to eq(incoming_sms_status_url)
      end

      context 'no environment variable is set' do
        before do
          ENV['UNCLAIMED_AUTOREPLY_MESSAGE'] = nil
        end

        it 'autoreply falls back to translation' do
          unknown_number = '+19999999999'
          params = twilio_new_message_params from_number: unknown_number, to_number: dept_phone_number

          time = Time.now.change(usec: 0)
          travel_to time do
            Message.create_from_twilio!(params)
          end

          job_args = enqueued_jobs.first[:args].first
          message = GlobalID::Locator.locate job_args['message']['_aj_globalid']
          expect(message).to_not be_nil
          expect(message.body).to eq(I18n.t('message.unclaimed_response'))
        end
      end

      context 'an empty environment variable is set' do
        before do
          ENV['UNCLAIMED_AUTOREPLY_MESSAGE'] = ' '
        end

        it 'autoreply falls back to translation' do
          unknown_number = '+19999999999'
          params = twilio_new_message_params from_number: unknown_number, to_number: dept_phone_number

          time = Time.now.change(usec: 0)
          travel_to time do
            Message.create_from_twilio!(params)
          end

          job_args = enqueued_jobs.first[:args].first
          message = GlobalID::Locator.locate job_args['message']['_aj_globalid']
          expect(message).to_not be_nil
          expect(message.body).to eq(I18n.t('message.unclaimed_response'))
        end
      end
    end

    context 'client exists' do
      let(:dept_phone_number) { '+17609996661' }
      let!(:user) { create :user, dept_phone_number: dept_phone_number }
      let!(:client) { create :client, users: [user] }

      it 'creates a message if proper params are sent' do
        params = twilio_new_message_params from_number: client.phone_number, to_number: dept_phone_number
        msg = Message.create_from_twilio!(params)
        expect(client.messages.last).to eq msg
      end

      context 'there is an attachment' do
        let(:params) do
          twilio_new_message_params(
            from_number: client.phone_number,
            to_number: dept_phone_number,
            msg_txt: body
          ).merge(NumMedia: 2,
                  MediaUrl0: 'http://cats.com/fluffy_cat.png',
                  MediaUrl1: 'http://cats.com/fluffy_cat.png',
                  MediaContentType0: 'text/png',
                  MediaContentType1: 'text/png')
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

        subject { Message.create_from_twilio!(params) }

        context 'message body is present' do
          let(:body) { 'some_body' }

          it 'creates a message with attachments' do
            attachments = subject.attachments.all
            expect(attachments.length).to eq 2

            attachments.each do |attachment|
              expect(attachment.media.exists?).to eq true
            end
          end
        end

        context 'message body is not present' do
          let(:body) { '' }

          it 'creates a message with no body but an attachment' do
            attachments = subject.attachments.all
            expect(attachments.length).to eq 2

            attachments.each do |attachment|
              expect(attachment.media.exists?).to eq true
            end
          end
        end
      end
    end
  end

  describe 'create_transfer_marker' do
    let(:sending_user) { create :user }
    let(:receiving_user) { create :user }
    let(:client) { create :client, users: [receiving_user] }

    subject do
      Message.create_transfer_markers(
        sending_user: sending_user,
        receiving_user: receiving_user,
        client: client
      )
    end

    it 'creates two message with transfer_marker properties' do
      time = Time.now.change(usec: 0)

      travel_to time do
        subject
      end
      transfer_marker_from = receiving_user.messages.transfer_markers.first
      expect(transfer_marker_from.user).to eq(receiving_user)
      expect(transfer_marker_from.client).to eq(client)
      expect(transfer_marker_from.send_at).to eq(time)
      transfer_marker_body = I18n.t(
        'messages.transferred_from',
        user_full_name: sending_user.full_name,
        client_full_name: client.full_name
      )
      expect(transfer_marker_from.body).to eq(transfer_marker_body)
      expect(transfer_marker_from).to be_transfer_marker
      expect(transfer_marker_from).to be_persisted

      transfer_marker_to = sending_user.messages.transfer_markers.first
      expect(transfer_marker_to.user).to eq(sending_user)
      expect(transfer_marker_to.client).to eq(client)
      expect(transfer_marker_to.send_at).to eq(time)
      transfer_marker_body = I18n.t(
        'messages.transferred_to',
        user_full_name: receiving_user.full_name
      )
      expect(transfer_marker_to.body).to eq(transfer_marker_body)
      expect(transfer_marker_to).to be_transfer_marker
      expect(transfer_marker_to).to be_persisted
    end
  end

  describe 'scope transfer_markers' do
    let(:user) { create :user }
    let(:client) { create :client, users: [user] }
    let(:transfer_marker) { create :message, client: client, user: user, transfer_marker: true }

    subject { client.messages.transfer_markers }

    it 'finds the transfer markers' do
      create_list :message, 5, user: user, client: client

      expect(subject).to contain_exactly(transfer_marker)
    end
  end

  describe 'scope messages' do
    let(:user) { create :user }
    let(:client) { create :client, users: [user] }
    let(:message) { create :message, client: client, user: user }

    subject { client.messages.messages }

    it 'finds the message' do
      create_list :message, 5, user: user, client: client, transfer_marker: true

      expect(subject).to contain_exactly(message)
    end
  end

  describe '#send_message' do
    let(:user) { create :user }
    let(:client) { create :client, users: [user] }
    let(:message) { create :message, client: client, user: user }

    subject { message.send_message }

    it 'sends message' do
      subject
      expect(ScheduledMessageJob).to have_been_enqueued.with(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url).at(message.send_at)
    end

    context 'send_at before now' do
      it 'runs MessageBroadcastJob' do
        expect(MessageBroadcastJob).to receive(:perform_now).with(
          message: message
        )

        subject
      end
    end
  end
end
