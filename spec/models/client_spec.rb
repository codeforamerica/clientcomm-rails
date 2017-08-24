require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'relationships' do
    it {
      should belong_to(:user)
      should have_many(:messages)
    }
  end

  describe 'accessors' do
    subject { create :client }

    describe '#full_name' do
      it 'formats full name' do
        expect(subject.full_name).to eq(subject.first_name + " " + subject.last_name)
      end
    end

    describe '#phone_number=' do
      it 'normalizes phone number' do
        subject.phone_number = '2435551212'
        expect(subject.phone_number).to eq '+12435551212'
      end
    end
  end

  describe 'validations' do
    it {
      should validate_presence_of(:last_name)
    }

    it 'validates presence of phone_number' do
      client = Client.new(last_name: 'Last')
      expect(client.valid?).to be_falsey
      expect([:phone_number]).to eq client.errors.keys
    end

    it 'validates uniqueness of phone_number' do
      old_client = create(:client)
      new_client = build(:client, phone_number: old_client.phone_number)
      expect(new_client.valid?).to be_falsey
      expect([:phone_number]).to eq new_client.errors.keys
    end
  end

  describe '#analytics_tracker_data' do
    it 'shows data about the client' do
      client = create :client, id: 4, notes: 'some notes'
      create :message, client: client, read: false, inbound: true
      create :message, client: client, read: false, inbound: true
      create :message, client: client, read: false, inbound: false
      create :message, client: client, read: false, inbound: false
      create :message, client: client, read: false, inbound: false
      create :message, client: client, read: false, inbound: false, send_at: Time.current + 10.days

      expect(client.analytics_tracker_data).to include(
          client_id: 4,
          has_unread_messages: true,
          messages_all_count: 6,
          messages_received_count: 2,
          messages_sent_count: 4,
          messages_attachments_count: 0,
          messages_scheduled_count: 1,
          has_client_notes: true
      )
    end
  end

end
