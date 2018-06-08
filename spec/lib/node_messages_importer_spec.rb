require 'rails_helper'

describe NodeMessagesImporter do
  let(:convo_id_1) { '111' }
  let(:cm_id_1) { '18' }
  let(:comm_id) { '91' }
  let(:message_body) { 'This is my anonymous message body' }
  let(:message_created) { '2016-03-23 12:59:29.35076-07' }
  let(:twilio_sid) { 'SM99999999999999999999999999999999' }
  let(:twilio_status) { 'received' }
  let(:read) { 't' }
  let(:read_boolean) { ActiveModel::Type::Boolean.new.cast(read) }
  let(:inbound) { 't' }
  let(:inbound_boolean) { ActiveModel::Type::Boolean.new.cast(inbound) }
  let(:client_number) { client.phone_number }
  let(:client_number_normalized) { client_number }
  let(:message_segments) do
    [
      {
        'cm' => cm_id_1,
        'comm' => comm_id,
        'content' => message_body,
        'convid' => convo_id_1,
        'created' => message_created,
        'inbound' => inbound,
        'read' => read,
        'tw_sid' => twilio_sid,
        'tw_status' => twilio_status,
        'value' => client_number
      }
    ]
  end

  let(:user_1) { create :user, node_id: cm_id_1 }
  let(:client) { create :client, node_comm_id: comm_id }
  let!(:rr) { create :reporting_relationship, user: user_1, client: client }

  subject { described_class.import_message(message_segments) }

  context 'parsing an incoming message' do
    it 'creates an incoming message object' do
      subject
      message = rr.messages.find_by(twilio_sid: twilio_sid)
      expect(message).to_not be_nil
      expect(message.body).to eq message_body
      expect(message.send_at).to eq Time.parse(message_created).utc
      expect(message.sent). to eq false
      expect(message.inbound).to eq inbound_boolean
      expect(message.read).to eq read_boolean
      expect(message.twilio_status).to eq twilio_status
      expect(message.number_from).to eq client_number_normalized
    end

    context 'a message with the same sid already exists' do
      let!(:already_existing_message) { create :text_message, twilio_sid: twilio_sid }

      it 'does not create a new message' do
        subject
        messages = Message.where(twilio_sid: twilio_sid)
        expect(messages.count).to eq 1
      end
    end

    context 'the message body is blank' do
      let(:message_body) { '  ' }

      it 'does not create a message' do
        subject
        messages = Message.where(twilio_sid: twilio_sid)
        expect(messages.count).to eq 0
      end
    end

    context 'the message has an attached recording' do
      let(:twilio_sid) { 'RE73917v2w74927ob7492g8r3m47l37491' }
      let(:account_sid) { 'AC82k8ej5w9m4e629vw6g6f83n36128934' }
      let(:media_url) { "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Recordings/#{twilio_sid}" }

      before do
        @account_sid = ENV['TWILIO_ACCOUNT_SID']
        ENV['TWILIO_ACCOUNT_SID'] = account_sid
      end

      after do
        ENV['TWILIO_ACCOUNT_SID'] = @account_sid
      end

      before do
        stub_request(:get, media_url)
          .to_return(status: 200,
                     body: File.read('spec/fixtures/fluffy_cat.jpg'),
                     headers: {
                       'Accept-Ranges' => 'bytes',
                       'Content-Length' => '4379330',
                       'Content-Type' => 'image/jpeg'
                     })
      end

      it 'attaches the sound file to the message' do
        subject
        message = Message.last

        expect(message.attachments.length).to eq(1)
        expect(message.attachments.first.media.exists?).to eq(true)
      end
    end

    context 'the message has multiple segments' do
      let(:convo_id_2) { convo_id_1 }
      let(:cm_id_2) { cm_id_1 }
      let(:message_body_segment_1) { 'This text is contained in segment 1 of my anonymous message ' }
      let(:message_body_segment_2) { 'body and this text is contained in segment 2' }
      let(:message_body_full) { [message_body_segment_1, message_body_segment_2].join }
      let(:message_segments) do
        [
          {
            'cm' => cm_id_1,
            'comm' => comm_id,
            'content' => message_body_segment_1,
            'convid' => convo_id_1,
            'created' => message_created,
            'inbound' => inbound,
            'read' => read,
            'tw_sid' => twilio_sid,
            'tw_status' => twilio_status,
            'value' => client_number
          },
          {
            'cm' => cm_id_2,
            'comm' => comm_id,
            'content' => message_body_segment_2,
            'convid' => convo_id_2,
            'created' => message_created,
            'inbound' => inbound,
            'read' => read,
            'tw_sid' => twilio_sid,
            'tw_status' => twilio_status,
            'value' => client_number
          }
        ]
      end

      it 'creates a single message object' do
        subject
        messages = rr.messages.where(twilio_sid: twilio_sid)
        expect(messages.count).to eq 1
        message = messages.first
        expect(message.body).to eq message_body_full
        expect(message.send_at).to eq Time.parse(message_created).utc
        expect(message.sent). to eq false
        expect(message.inbound).to eq inbound_boolean
        expect(message.read).to eq read_boolean
        expect(message.twilio_status).to eq twilio_status
        expect(message.number_from).to eq client_number_normalized
      end

      context 'there are duplicate messages attached to different conversations with different users, only one is active' do
        let(:convo_id_2) { '222' }
        let(:cm_id_2) { '19' }
        let(:message_body_segment_1) { 'This is a single, self-contained message' }
        let(:message_body_segment_2) { message_body_segment_1 }
        let(:message_body_full) { message_body_segment_1 }
        let(:user_2) { create :user, node_id: cm_id_2 }

        it 'creates a single message object' do
          subject
          messages = rr.messages.where(twilio_sid: twilio_sid)
          expect(messages.count).to eq 1
          message = messages.first
          expect(message.body).to eq message_body_full
          expect(message.send_at).to eq Time.parse(message_created).utc
          expect(message.inbound).to eq inbound_boolean
          expect(message.read).to eq read_boolean
          expect(message.sent). to eq false
          expect(message.twilio_status).to eq twilio_status
          expect(message.number_from).to eq client_number_normalized
        end
      end

      context 'there are duplicate messages attached to different conversations with the same user' do
        let(:convo_id_2) { '222' }
        let(:message_body_segment_1) { 'This is a single, self-contained message' }
        let(:message_body_segment_2) { message_body_segment_1 }
        let(:message_body_full) { message_body_segment_1 }

        it 'creates a single message object' do
          subject
          messages = rr.messages.where(twilio_sid: twilio_sid)
          expect(messages.count).to eq 1
          message = messages.first
          expect(message.body).to eq message_body_full
          expect(message.send_at).to eq Time.parse(message_created).utc
          expect(message.sent). to eq false
          expect(message.inbound).to eq inbound_boolean
          expect(message.read).to eq read_boolean
          expect(message.twilio_status).to eq twilio_status
          expect(message.number_from).to eq client_number_normalized
        end
      end
    end
  end

  context 'parsing an outgoing message' do
    let(:inbound) { 'f' }
    let(:read) { 'f' }

    it 'creates an outgoing message object' do
      subject
      message = rr.messages.find_by(twilio_sid: twilio_sid)
      expect(message.inbound).to eq inbound_boolean
      expect(message.number_from).to eq user_1.department.phone_number
      expect(message.number_to).to eq client_number_normalized
      expect(message.read).to eq true
      expect(message.sent). to eq true
    end
  end
end
