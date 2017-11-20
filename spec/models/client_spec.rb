require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'relationships' do
    it { should have_many(:users).through(:reporting_relationships) }
    it { should belong_to :client_status }
    it { should have_many :messages }
    it { should have_many(:attachments).through(:messages) }
  end

  describe 'accessors' do
    subject { create :client, first_name: 'zak', last_name: 'mark' }

    describe '#full_name' do
      it 'formats full name' do
        expect(subject.full_name).to eq('zak mark')
      end
    end
  end

  describe 'normalizing' do
    let(:input_phone_number) { '(760) 555-7890' }
    let(:normalized_phone_number) { '+17605557890' }
    let(:user_number) { 'fake_phone_number' }

    before do
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: user_number)
        .and_return('fake_normal_number')
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: input_phone_number)
        .and_return(normalized_phone_number)
    end

    subject { create :client, phone_number: input_phone_number }

    it 'formats the phone number' do
      expect(subject.reload.phone_number).to eq(normalized_phone_number)
    end
  end

  describe 'validations' do
    let(:user) { create :user, phone_number: 'fake_phone_number', department: nil }

    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number) }

    it 'validates correctness of phone_number' do
      bad_number = '(212) 55-5236'
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: 'fake_phone_number')
        .and_return('fake_normal_number')

      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: bad_number)
        .and_raise(SMSService::NumberNotFound)

      new_client = build(:client, phone_number: bad_number, user: user)
      expect(new_client.valid?).to eq(false)
      expect(new_client.errors.keys).to contain_exactly(:phone_number)
    end

    it 'does not validate correctness of phone_number if phone number unchanged' do
      client = create :client
      allow(SMSService.instance).to receive(:number_lookup)
      client.update!(first_name: 'some other name')
      expect(SMSService.instance).to_not have_received(:number_lookup)
    end
  end

  describe '#analytics_tracker_data' do
    it 'shows data about the client' do
      client = create :client, id: 4, notes: 'some notes', has_unread_messages: true, last_contacted_at: Time.now

      create :message, client: client, inbound: true
      create :message, client: client, inbound: true
      create :message, client: client, inbound: false
      create :message, client: client, inbound: false
      create :message, client: client, inbound: false
      create :message, client: client, inbound: false, send_at: Time.current + 10.days

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
