require 'rails_helper'

describe NodeMessagesImporter do
  let(:cm_id) { '8' }
  let(:comm_id) { '9' }
  let(:message_body) { 'This is my anonymous message body' }
  let(:message_created) { '2016-03-23 12:59:29.35076-07' }
  let(:twilio_sid) { 'SM99999999999999999999999999999999' }
  let(:twilio_status) { 'received' }
  let(:read) { 't' }
  let(:read_boolean) { true }
  let(:inbound) { 't' }
  let(:inbound_boolean) { true }
  let(:client_number) { '14155554321' }
  let(:client_number_normalized) { "+#{client_number}" }
  let(:message_segments) do
    [
      {
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
    it 'creates a message that matches the passed data' do
      subject
      message = rr.messages.find_by(twilio_sid: twilio_sid)
      expect(message).to_not be_nil
      expect(message.body).to eq(message_body)
      expect(message.send_at).to eq(Time.parse(message_created).utc)
      expect(message.inbound).to eq(inbound_boolean)
      expect(message.read).to eq(read_boolean)
      expect(message.twilio_status).to eq(twilio_status)
      expect(message.number_from).to eq(client_number_normalized)
    end

    context 'the message has multiple segments' do
      let(:message_body_segment_1) { 'This is segment 1 of my anonymous message body' }
      let(:message_body_segment_2) { 'This is segment 2 of my anonymous message body' }
      let(:message_segments) do
        [
          {
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
    end
  end

  context 'parsing an outgoing message' do
    let(:inbound) { 'f' }
    let(:inbound_boolean) { false }

    it 'creates a message that matches the passed data' do
      subject
      message = rr.messages.find_by(twilio_sid: twilio_sid)
      expect(message.number_from).to eq(user.department.phone_number)
      expect(message.number_to).to eq(client_number_normalized)
    end
  end
end
