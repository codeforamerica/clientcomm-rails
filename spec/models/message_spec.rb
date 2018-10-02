require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'validations' do
    it { should validate_length_of(:body).is_at_most(1600) }
    it { should belong_to :like_message }
    it { should validate_exclusion_of(:type).in_array(['Message']) }

    context 'like_message has different rr' do
      let(:like_message) { create :text_message }
      it 'is invalid' do
        message = build :text_message, like_message: like_message
        expect(message).to_not be_valid
      end
    end
  end

  describe '#first?' do
    let(:message) { create :text_message, send_at: send_at }
    let(:rr) { message.reporting_relationship }

    before do
      create :text_message, reporting_relationship: rr, send_at: Time.zone.local(2010, 1, 1, 1, 1, 2)
      create :text_message, reporting_relationship: rr, send_at: Time.zone.local(2010, 1, 1, 1, 1, 3)
      create :text_message, reporting_relationship: rr, send_at: Time.zone.local(2010, 1, 1, 1, 1, 4)
    end

    subject do
      message.first?
    end

    context 'message is first' do
      let(:send_at) { Time.zone.local(2010, 1, 1, 1, 1, 1) }

      it 'sends analytics tracking data' do
        expect(subject).to eq true
      end
    end

    context 'message is not first' do
      let(:send_at) { Time.zone.local(2010, 1, 1, 1, 1, 5) }

      it 'sends analytics tracking data' do
        expect(subject).to eq false
      end
    end
  end

  describe 'marker?' do
    let(:message) { build :text_message }
    it 'is not a marker by default' do
      expect(message).to_not be_marker
    end

    context 'the marker is a marker type' do
      let(:message) { build :transfer_marker }
      it 'is not a marker by default' do
        expect(message).to be_marker
      end
    end

    context 'court reminder is non-marker' do
      let(:message) { build :court_reminder }
      it 'is not a marker by default' do
        expect(message).to_not be_marker
      end
    end
  end

  describe 'analytics_tracker_data' do
    let(:body_length) { 10 }
    let(:body) { Faker::Lorem.characters(body_length) }
    let(:send_at) { Time.zone.local(2010, 1, 1, 1, 1, 1) }
    let(:created_at) { Time.zone.local(2009, 2, 1, 1, 1, 1) }
    let!(:user) { create :user }
    let!(:client) { create :client, user: user }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let(:message) do
      create(
        :text_message,
        reporting_relationship: rr,
        send_at: send_at,
        created_at: created_at,
        body: body,
        inbound: false
      )
    end

    subject do
      message.analytics_tracker_data
    end

    it 'sends analytics tracking data' do
      expect(subject).to include(
        client_id: client.id,
        message_id: message.id,
        message_date_scheduled: send_at,
        message_date_created: created_at,
        message_length: body_length,
        current_user_id: user.id,
        attachments_count: 0,
        client_active: true, # Default
        first_message: true,
        created_by: 'user'
      )
    end

    context 'message is a CourtReminder' do
      let(:message) do
        create(
          :court_reminder,
          reporting_relationship: rr,
          send_at: send_at,
          created_at: created_at,
          body: body
        )
      end

      subject do
        message.analytics_tracker_data
      end

      it 'sets created by to auto-uploader' do
        expect(subject).to include(
          created_by: 'auto-uploader'
        )
      end
    end

    context 'there are many messages' do
      let(:send_at) { Time.zone.local(2010, 1, 1, 1, 1, 5) }

      before do
        create :text_message, reporting_relationship: rr, send_at: Time.zone.local(2010, 1, 1, 1, 1, 2)
        create :text_message, reporting_relationship: rr, send_at: Time.zone.local(2010, 1, 1, 1, 1, 3)
        create :text_message, reporting_relationship: rr, send_at: Time.zone.local(2010, 1, 1, 1, 1, 4)
      end

      it 'sends analytics tracking data' do
        expect(subject).to include(
          first_message: false
        )
      end
    end

    context 'client is inactive' do
      let(:client) { create :client, user: user, active: false }

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
      message = build :text_message, reporting_relationship: rr
      expect(message.original_reporting_relationship).to be_nil
      message.save!
      expect(message.original_reporting_relationship).to eq(rr)
    end

    it 'does not change original_reporting_relationship on update' do
      rr = create :reporting_relationship
      message = create :text_message, reporting_relationship: rr
      expect(message.original_reporting_relationship).to eq(rr)
      new_rr = create :reporting_relationship
      message.reporting_relationship = new_rr
      message.save!
      expect(message.original_reporting_relationship).to eq(rr)
      expect(message.reporting_relationship).to eq(new_rr)
    end

    context 'validating body of message' do
      it 'does not validate message with empty body with no attachments' do
        m = TextMessage.create(body: '')
        expect(m.errors[:body].present?).to eq true
      end

      it 'validates empty body with attachment' do
        m = build :text_message, body: ''
        m.attachments << build(:attachment)

        expect(m).to be_valid
      end

      it 'validates empty body for incoming messages' do
        m = build :text_message, body: '', inbound: true

        expect(m).to be_valid
      end
    end

    it 'should validate that a message is scheduled in the future' do
      expect(Message.new.past_message?).to be_falsey

      expect(Message.new(send_at: Time.current - 1.day).past_message?).to be_truthy

      expect(Message.new(send_at: Time.current).past_message?).to be_falsey
      expect(Message.new(send_at: Time.current + 5.minutes).past_message?).to be_falsey

      message = TextMessage.new(send_at: Time.current - 1.day)
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
                MediaUrl0: 'http://cats.com/fluffy_cat.jpg',
                MediaUrl1: 'http://cats.com/fluffy_cat.jpg',
                MediaContentType0: 'image/jpeg',
                MediaContentType1: 'image/jpeg')
      end

      before do
        stub_request(:get, 'http://cats.com/fluffy_cat.jpg')
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

        expect(subject.any_image_attachments?).to eq true
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

    context 'there is a non-image attachment' do
      let(:body) { '' }
      let(:twilio_params) do
        twilio_new_message_params(
          from_number: unknown_number,
          to_number: department.phone_number,
          msg_txt: body
        ).merge(NumMedia: 1,
                MediaUrl0: 'http://cats.com/cat_contact.vcf',
                MediaContentType0: 'text/x-vcard')
      end

      before do
        stub_request(:get, 'http://cats.com/cat_contact.vcf')
          .to_return(status: 200,
                     body: File.read('spec/fixtures/cat_contact.vcf'),
                     headers: {
                       'Accept-Ranges' => 'bytes',
                       'Content-Length' => '162',
                       'Content-Type' => 'text/x-vcard'
                     })
      end

      it 'creates a message with an attachment' do
        attachments = subject.attachments.all
        expect(attachments.length).to eq 1
        expect(attachments.first.media.exists?).to eq true
        expect(subject.any_image_attachments?).to eq false
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
          let(:rr) { ReportingRelationship.find_by(user: user, client: client) }

          before do
            rr.update(active: false)
          end

          it 'reactivates the inactive relationship' do
            message = subject
            expect(message.user).to eq(user)
          end

          context 'the client has an active relationship with an older updated_at' do
            let(:less_recent_active_user) { create :user, department: department }

            before do
              create :reporting_relationship, user: less_recent_active_user, client: client
              travel_to Time.zone.now + 1.day
              rr.update(updated_at: Time.zone.now)
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

  describe 'send_unclaimed_autoreply' do
    let(:user) { create :user }
    let(:client) { create :client, users: [user] }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let(:message) { instance_double(Message) }
    let(:status_callback) { Rails.application.routes.url_helpers.incoming_sms_status_url }
    let(:now) { Time.zone.now.change(usec: 0) }

    subject { Message.send_unclaimed_autoreply(rr: rr) }

    it 'sends the autoreply message' do
      expect(TextMessage).to receive(:create!) .with(
        reporting_relationship: rr,
        inbound: false,
        read: true,
        body: I18n.t('message.unclaimed_response'),
        send_at: now
      ).and_return(message)

      expect(message).to receive(:send_message)

      travel_to now do
        subject
      end
    end
  end

  describe 'create_conversation_ends_marker' do
    let(:user) { create :user }
    let(:client_first_name) { 'Lucille' }
    let(:client_last_name) { 'Cooper' }
    let(:client_full_name) { "#{client_first_name} #{client_last_name}" }
    let(:client_phone_number) { '+14155551111' }
    let!(:client) {
      create :client,
             user: user,
             first_name: client_first_name,
             last_name: client_last_name,
             phone_number: client_phone_number
    }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }

    subject do
      Message.create_conversation_ends_marker(
        reporting_relationship: rr,
        full_name: client_full_name,
        phone_number: client_phone_number
      )
    end

    context 'there are messages in the conversation' do
      before do
        5.times { |n| create :text_message, reporting_relationship: rr, send_at: Time.zone.now - (1 + n).days }
      end

      it 'creates a marker with conversation ends marker properties' do
        subject

        marker_conversation_ends = rr.messages.where(type: ConversationEndsMarker.to_s).first
        expect(marker_conversation_ends.user).to eq(user)
        expect(marker_conversation_ends.client).to eq(client)
        expect(marker_conversation_ends.send_at).to eq(rr.messages.messages.order(send_at: :desc).first.send_at + 1.second)
        marker_body = I18n.t('messages.conversation_ends', full_name: client_full_name, phone_number: client_phone_number)
        expect(marker_conversation_ends.body).to eq(marker_body)
        expect(marker_conversation_ends).to be_conversation_ends_marker
        expect(marker_conversation_ends).to be_persisted
        expect(marker_conversation_ends).to be_read
      end
    end

    context 'there are no messages in the conversation' do
      it 'does not create a marker' do
        subject

        expect(rr.messages.where(type: ConversationEndsMarker.to_s).first).to be_nil
      end
    end
  end

  describe 'create_merged_with_marker' do
    let(:user) { create :user }
    let(:from_client_first_name) { 'Lucille' }
    let(:from_client_last_name) { 'Cooper' }
    let(:from_client_full_name) { "#{from_client_first_name} #{from_client_last_name}" }
    let(:from_client_phone_number) { '+14155551111' }
    let!(:from_client) {
      create :client,
             user: user,
             first_name: from_client_first_name,
             last_name: from_client_last_name,
             phone_number: from_client_phone_number
    }
    let(:to_client_first_name) { 'Amanda' }
    let(:to_client_last_name) { 'Aguirre' }
    let(:to_client_full_name) { "#{to_client_first_name} #{to_client_last_name}" }
    let(:to_client_phone_number) { '+14155551112' }
    let!(:to_client) {
      create :client,
             user: user,
             first_name: to_client_first_name,
             last_name: to_client_last_name,
             phone_number: to_client_phone_number
    }
    let(:rr) { ReportingRelationship.find_by(user: user, client: to_client) }

    subject do
      Message.create_merged_with_marker(
        reporting_relationship: rr,
        from_full_name: from_client_full_name,
        to_full_name: to_client_full_name,
        from_phone_number: from_client_phone_number,
        to_phone_number: to_client_phone_number
      )
    end

    it 'creates a message with merged with marker properties' do
      time = Time.zone.now.change(usec: 0)

      travel_to time do
        subject
      end

      marker_merged = rr.messages.where(type: MergedWithMarker.to_s).first
      expect(marker_merged.user).to eq(user)
      expect(marker_merged.client).to eq(to_client)
      expect(marker_merged.send_at).to eq(time)
      marker_body = I18n.t(
        'messages.merged_with',
        from_full_name: from_client_full_name,
        from_phone_number: from_client_phone_number,
        to_full_name: to_client_full_name,
        to_phone_number: to_client_phone_number
      )
      expect(marker_merged.body).to eq(marker_body)
      expect(marker_merged).to be_merged_with_marker
      expect(marker_merged).to be_persisted
      expect(marker_merged).to be_read
    end
  end

  describe 'create_client_edit_markers' do
    let(:editing_user) { create :user, full_name: 'Lisa Sokol' }
    let!(:other_user) { create :user, full_name: 'Kyle Chan' }
    let!(:client) { create :client, user: editing_user }
    let(:editing_rr) { ReportingRelationship.find_by(user: editing_user, client: client) }
    let(:other_rr) { create :reporting_relationship, user: other_user, client: client }
    let(:new_phone_number) { '(415) 555-1234' }
    let(:as_admin) { false }

    subject do
      Message.create_client_edit_markers(
        user: editing_user,
        phone_number: new_phone_number,
        reporting_relationships: [editing_rr, other_rr],
        as_admin: as_admin
      )
    end

    it 'creates two messages with client edit marker properties' do
      time = Time.zone.now.change(usec: 0)

      travel_to time do
        subject
      end

      marker_editing = editing_user.messages.where(type: ClientEditMarker.to_s).first
      expect(marker_editing.user).to eq(editing_user)
      expect(marker_editing.client).to eq(client)
      expect(marker_editing.send_at).to eq(time)
      marker_body = I18n.t(
        'messages.phone_number_edited_by_you',
        new_phone_number: new_phone_number
      )
      expect(marker_editing.body).to eq(marker_body)
      expect(marker_editing).to be_client_edit_marker
      expect(marker_editing).to be_persisted
      expect(marker_editing).to be_read

      marker_other = other_user.messages.where(type: ClientEditMarker.to_s).first
      expect(marker_other.user).to eq(other_user)
      expect(marker_other.client).to eq(client)
      expect(marker_other.send_at).to eq(time)
      marker_body = I18n.t(
        'messages.phone_number_edited',
        user_full_name: editing_user.full_name,
        new_phone_number: new_phone_number
      )
      expect(marker_other.body).to eq(marker_body)
      expect(marker_other).to be_client_edit_marker
      expect(marker_other).to be_persisted
      expect(marker_other).to be_read
    end
  end

  describe 'create_transfer_markers' do
    let(:sending_user) { create :user }
    let(:receiving_user) { create :user }
    let(:client) { create :client }
    let(:sending_rr) { create :reporting_relationship, user: sending_user, client: client, active: false }
    let(:receiving_rr) { create :reporting_relationship, user: receiving_user, client: client }

    subject do
      Message.create_transfer_markers(
        sending_rr: sending_rr,
        receiving_rr: receiving_rr
      )
    end

    it 'creates two message with transfer_marker properties' do
      time = Time.zone.now.change(usec: 0)

      travel_to time do
        subject
      end
      transfer_marker_from = receiving_user.messages.where(type: TransferMarker.to_s).first
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

      transfer_marker_to = sending_user.messages.where(type: TransferMarker.to_s).first
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

    context 'the clients in the reporting relationships do not match' do
      let(:other_client) { create :client }
      let(:receiving_rr) { create :reporting_relationship, user: receiving_user, client: other_client }

      it 'raises an exception' do
        expect { subject }.to raise_error(Message::TransferClientMismatch)
      end
    end
  end

  describe 'scope messages' do
    let(:rr) { create :reporting_relationship }
    let(:message) { create :text_message, reporting_relationship: rr }

    subject { rr.messages.messages }

    it 'finds the message' do
      create_list :text_message, 3, reporting_relationship: rr, type: TransferMarker.to_s
      create_list :text_message, 3, reporting_relationship: rr, type: ClientEditMarker.to_s

      expect(subject).to contain_exactly(message)
    end

    context 'the message is an auto court reminder' do
      let(:message) { create :court_reminder, reporting_relationship: rr }

      it 'finds the message' do
        create_list :text_message, 3, reporting_relationship: rr, type: TransferMarker.to_s
        create_list :text_message, 3, reporting_relationship: rr, type: ClientEditMarker.to_s

        expect(subject).to contain_exactly(message)
      end
    end
  end

  describe '#send_message', active_job: true do
    let(:rr) { create :reporting_relationship }
    let!(:message) { create :text_message, reporting_relationship: rr, sent: false, send_at: Time.zone.now }

    subject { message.send_message }

    it 'sends message' do
      subject
      expect(ScheduledMessageJob).to have_been_enqueued.with(message: message).at(message.send_at)
    end

    context 'sent is ture' do
      let!(:message) { create :text_message, reporting_relationship: rr, sent: true, send_at: Time.zone.now }
      it 'runs MessageBroadcastJob' do
        expect(MessageBroadcastJob).to_not receive(:perform_now).with(
          message: message
        )
        subject
        expect(ScheduledMessageJob).to_not have_been_enqueued
      end
    end

    context 'send_at after now' do
      let!(:message) { create :text_message, reporting_relationship: rr, sent: false, send_at: Time.zone.now + 1.day }
      it 'runs MessageBroadcastJob' do
        expect(MessageBroadcastJob).to_not receive(:perform_now).with(
          message: message
        )
        subject
        expect(ScheduledMessageJob).to_not have_been_enqueued
      end
    end
  end
end
