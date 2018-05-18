require 'rails_helper'

describe NodeMessagesImporter do
  let(:convo_id) { '111' }
  let(:cm_id) { '8' }
  let(:comm_id) { '9' }
  let(:message_body) { 'This is my anonymous message body' }
  let(:message_created) { '2016-03-23 12:59:29.35076-07' }
  let(:twilio_sid) { 'SM99999999999999999999999999999999' }
  let(:twilio_status) { 'received' }
  let(:read) { 't' }
  let(:read_boolean) { ActiveModel::Type::Boolean.new.cast(read) }
  let(:inbound) { 't' }
  let(:inbound_boolean) { ActiveModel::Type::Boolean.new.cast(inbound) }
  let(:client_number) { '14155554321' }
  let(:client_number_normalized) { "+#{client_number}" }
  let(:message_segments) do
    [
      {
        'convid' => convo_id,
        'cm' => cm_id,
        'comm' => comm_id,
        'content' => message_body,
        'created' => message_created,
        'inbound' => inbound,
        'read' => read,
        'tw_sid' => twilio_sid,
        'tw_status' => twilio_status,
        'value' => client_number
      }
    ]
  end

  let(:user) { create :user, node_id: cm_id }
  let(:client) { create :client, node_comm_id: comm_id }
  let!(:rr) { create :reporting_relationship, user: user, client: client }

  subject { described_class.import_message(message_segments) }

  context 'parsing an incoming message' do
    it 'creates an incoming message object' do
      subject
      message = rr.messages.find_by(twilio_sid: twilio_sid)
      expect(message).to_not be_nil
      expect(message.body).to eq message_body
      expect(message.send_at).to eq Time.parse(message_created).utc
      expect(message.inbound).to eq inbound_boolean
      expect(message.read).to eq read_boolean
      expect(message.twilio_status).to eq twilio_status
      expect(message.number_from).to eq client_number_normalized
    end

    context 'the message has an attached recording' do
    end

    context 'the message has multiple segments' do
      let(:message_body_segment_1) { 'This is segment 1 of my anonymous message body and ' }
      let(:message_body_segment_2) { 'this text is contained in segment 2' }
      let(:message_body_full) { [message_body_segment_1, message_body_segment_2].join }
      let(:message_segments) do
        [
          {
            'convid' => convo_id,
            'cm' => cm_id,
            'comm' => comm_id,
            'content' => message_body_segment_1,
            'created' => message_created,
            'inbound' => inbound,
            'read' => read,
            'tw_sid' => twilio_sid,
            'tw_status' => twilio_status,
            'value' => client_number
          },
          {
            'convid' => convo_id,
            'cm' => cm_id,
            'comm' => comm_id,
            'content' => message_body_segment_2,
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
        expect(message.inbound).to eq inbound_boolean
        expect(message.read).to eq read_boolean
        expect(message.twilio_status).to eq twilio_status
        expect(message.number_from).to eq client_number_normalized
      end

      context 'there are duplicate message segments' do
        context 'only one of the duplicates can be matched to an active relationship' do
        end
        context 'multiple duplicates belong to the same active relationship' do
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
      expect(message.number_from).to eq user.department.phone_number
      expect(message.number_to).to eq client_number_normalized
      expect(message.read).to eq true
    end
  end
end
