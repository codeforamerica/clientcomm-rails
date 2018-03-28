require 'rails_helper'

RSpec.describe Message, type: :model do
  describe '#first?' do
    let(:message) { create :message, send_at: send_at }
    let(:rr) { message.reporting_relationship }

    before do
      create :message, reporting_relationship: rr, send_at: Time.new(2010, 1, 1, 1, 1, 2)
      create :message, reporting_relationship: rr, send_at: Time.new(2010, 1, 1, 1, 1, 3)
      create :message, reporting_relationship: rr, send_at: Time.new(2010, 1, 1, 1, 1, 4)
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
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let(:message) do
      create(
        :message,
        reporting_relationship: rr,
        send_at: send_at,
        created_at: created_at,
        body: body
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
        create :message, reporting_relationship: rr, send_at: Time.new(2010, 1, 1, 1, 1, 2)
        create :message, reporting_relationship: rr, send_at: Time.new(2010, 1, 1, 1, 1, 3)
        create :message, reporting_relationship: rr, send_at: Time.new(2010, 1, 1, 1, 1, 4)
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
    it { should have_one :client }
    it { should have_one :user }
    it { should have_many :attachments }
    it { should validate_presence_of :reporting_relationship }

    it do
      should validate_presence_of(:send_at)
        .with_message("That date didn't look right.")
    end

    it 'sets the original_reporting_relationship before create validations' do
      rr = create :reporting_relationship
      message = build :message, reporting_relationship: rr
      expect(message.original_reporting_relationship).to be_nil
      message.save!
      expect(message.original_reporting_relationship).to eq(rr)
    end

    it 'does not change original_reporting_relationship on update' do
      rr = create :reporting_relationship
      message = create :message, reporting_relationship: rr
      expect(message.original_reporting_relationship).to eq(rr)
      new_rr = create :reporting_relationship
      message.reporting_relationship = new_rr
      message.save!
      expect(message.original_reporting_relationship).to eq(rr)
      expect(message.reporting_relationship).to eq(new_rr)
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

  describe '#create_from_twilio', active_job: true do
    let(:dept_phone_number) { '+17609996661' }
    let(:unknown_number) { '+19999999999' }
    let(:unclaimed_user) { create :user }
    let(:department) { create :department, users: [unclaimed_user], unclaimed_user: unclaimed_user, phone_number: dept_phone_number }
    let(:twilio_params) { twilio_new_message_params from_number: unknown_number, to_number: department.phone_number }

    subject { Message.create_from_twilio!(twilio_params) }

    before do
      allow(Message).to receive(:send_unclaimed_autoreply)
    end

    it 'creates a message with the proper information' do
      expect(subject.number_to).to eq department.phone_number
      expect(subject.number_from).to eq unknown_number
      expect(subject.inbound).to be_truthy
      expect(subject.send_at).to be_present
    end

    it 'creates the client' do
      client = subject.client
      expect(client.last_name).to eq('+19999999999')
    end

    it 'attaches the new client to the unclaimed user' do
      client = subject.client
      expect(client.users).to include(unclaimed_user)
    end

    it 'autoreplies to the message' do
      client = subject.client
      rr = ReportingRelationship.find_by(user: unclaimed_user, client: client)
      expect(Message).to have_received(:send_unclaimed_autoreply).with(rr: rr)
    end

    context 'there is an attachment' do
      let(:body) { '' }
      let(:twilio_params) do
        twilio_new_message_params(
          from_number: unknown_number,
          to_number: department.phone_number,
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

      it 'creates a message with an attachment' do
        attachments = subject.attachments.all
        expect(attachments.length).to eq 2

        attachments.each do |attachment|
          expect(attachment.media.exists?).to eq true
        end
      end

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
    end

    context 'client already exists' do
      let(:client) { create :client }
      let(:twilio_params) { twilio_new_message_params from_number: client.phone_number, to_number: department.phone_number }

      it 'assigns the client to the unclaimed user' do
        subject
        expect(client.users).to include(unclaimed_user)
      end

      it 'sends an autoreply' do
        subject
        rr = ReportingRelationship.find_by(user: unclaimed_user, client: client)
        expect(Message).to have_received(:send_unclaimed_autoreply).with(rr: rr)
      end

      context 'a second message is sent' do
        before do
          Message.create_from_twilio!(twilio_params)
        end

        it 'does not send an autoreply' do
          subject
          expect(Message).to have_received(:send_unclaimed_autoreply).exactly(:once)
        end
      end

      context 'the client already has a relationship with a user' do
        let(:user) { create :user, department: department }

        before do
          user.clients << client
        end

        it 'creates the message on the correct rr' do
          rr = ReportingRelationship.find_by(user: user, client: client)
          message = subject

          expect(rr.messages).to include(message)
        end

        context 'the user is in another department' do
          let(:user) { create :user }

          it 'attaches the client to the relevant unclaimed user' do
            subject
            expect(client.users).to include(unclaimed_user)
          end
        end

        context 'the client has an inactive relationship with a user' do
          before do
            ReportingRelationship.find_by(user: user, client: client).update(active: false)
          end

          it 'reactivates the inactive relationship'

          context 'the client has an active relationship with an older updated_at' do
            let(:less_recent_active_user) { create :user, department: department }

            before do
              create :reporting_relationship, user: less_recent_active_user, client: client
              travel_to Time.now + 1.day
              ReportingRelationship.find_by(user: user, client: client).update(updated_at: Time.now)
            end

            after do
              travel_back
            end

            it 'selects the active reporting realtionship' do
              message = subject
              expect(message.user).to eq(less_recent_active_user)
            end
          end
        end
      end
    end
  end

  describe 'send_unclaimed_autoreply', active_job: true do
    let(:user) { create :user }
    let(:client) { create :client, users: [user] }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let(:message) { instance_double(Message) }
    let(:callback_url) { Rails.application.routes.url_helpers.incoming_sms_status_url }
    let(:now) { Time.now.change(usec: 0) }

    subject { Message.send_unclaimed_autoreply(rr: rr) }

    it 'sends the autoreply message' do
      expect(Message).to receive(:create!) .with(
        reporting_relationship: rr,
        body: I18n.t('message.unclaimed_response'),
        number_from: user.department.phone_number,
        number_to: client.phone_number,
        send_at: now
      ).and_return(message)

      expect(ScheduledMessageJob).to receive(:perform_later)
        .with(message: message, send_at: now.to_i, callback_url: callback_url)

      travel_to now do
        subject
      end
    end
  end

  describe 'create_transfer_marker' do
    let(:sending_user) { create :user }
    let(:receiving_user) { create :user }
    let(:client) { create :client }
    let(:sending_rr) { create :reporting_relationship, user: sending_user, client: client, active: false }
    let(:receiving_rr) { create :reporting_relationship, user: receiving_user, client: client }

    before do
    end

    subject do
      Message.create_transfer_markers(
        sending_rr: sending_rr,
        receiving_rr: receiving_rr
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
      expect(transfer_marker_from).to be_read

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
      expect(transfer_marker_to).to be_read
    end

    context 'the clients in the rrs do not match' do
      let(:other_client) { create :client }
      let(:receiving_rr) { create :reporting_relationship, user: receiving_user, client: other_client }

      it 'raises an exception' do
        expect { subject }.to raise_error(Message::TransferClientMismatch)
      end
    end
  end

  describe 'scope transfer_markers' do
    let(:rr) { create :reporting_relationship }
    let(:transfer_marker) { create :message, reporting_relationship: rr, marker_type: Message::MARKER_TRANSFER }

    subject { rr.client.messages.transfer_markers }

    it 'finds the transfer markers' do
      create_list :message, 5, reporting_relationship: rr

      expect(subject).to contain_exactly(transfer_marker)
    end
  end

  describe 'scope messages' do
    let(:rr) { create :reporting_relationship }
    let(:message) { create :message, reporting_relationship: rr }

    subject { rr.client.messages.messages }

    it 'finds the message' do
      create_list :message, 5, reporting_relationship: rr, marker_type: Message::MARKER_TRANSFER

      expect(subject).to contain_exactly(message)
    end
  end

  describe '#send_message', active_job: true do
    let(:rr) { create :reporting_relationship }
    let!(:message) { create :message, reporting_relationship: rr }

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
