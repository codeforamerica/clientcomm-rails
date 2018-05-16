require 'rails_helper'

describe NodeMessagesImporter do
  let(:cm_id) { '8' }
  let(:comm_id) { '9' }
  let(:message_body) { 'This is my anonymous message body' }
  let(:message_segments) do
    [
      {
        'comm' => comm_id,
        'content' => message_body,
        'cm' => cm_id
      }
    ]
  end

  let(:user) { create :user, node_id: cm_id }
  let(:client) { create :client, node_comm_id: comm_id }
  let!(:rr) { create :reporting_relationship, user: user, client: client }

  subject { described_class.import_message(message_segments) }

  it 'turns the message set into a message' do
    subject
    expect(rr.messages.pluck(:body)).to contain_exactly(message_body)
  end
end
