require 'rails_helper'

RSpec.describe Client, type: :model do
  let(:user_number) { 'fake_user_number' }
  let(:client_number) { 'fake_client_number' }
  let(:department_number) { 'fake_department_number' }

  describe 'relationships' do
    it { should have_many(:users).through(:reporting_relationships) }
    it { should have_many :messages }
    it { should have_many(:attachments).through(:messages) }
    it { should have_many(:surveys) }
  end

  describe 'scoping' do
    let(:user) { create :user }
    let!(:active_clients) { create_list :client, 3, user: user }
    let!(:inactive_clients) { create_list :client, 3, user: user, active: false }

    before do
      new_user = create :user
      new_user.clients << active_clients.first
    end

    it 'only shows active clients' do
      expect(user.clients.active).to contain_exactly(*active_clients)
      expect(user.clients.active).to_not include(*inactive_clients)
    end
  end

  describe 'accessors' do
    let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }

    describe '#full_name' do
      it 'formats full name' do
        expect(client.full_name).to eq('Lorraine Collins')
      end
    end

    describe '#reporting_relationship:user' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let!(:rr) { ReportingRelationship.create(user: user, client: client) }

      it 'returns the relevant reporting relationship' do
        expect(client.reporting_relationship(user: user)).to eq(rr)
      end
    end

    describe '#last_contacted_at:user' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let(:time) { 1.day.ago }
      let!(:rr) { ReportingRelationship.create(user: user, client: client, last_contacted_at: time) }

      it 'returns the relevant reporting relationship' do
        expect(client.last_contacted_at(user: user).to_i).to eq(time.to_i)
      end
    end

    describe '#relationship_started:user' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let(:time) { 1.day.ago }
      let!(:rr) { ReportingRelationship.create(user: user, client: client, created_at: time) }

      it 'returns the relevant reporting relationship' do
        expect(client.relationship_started(user: user).to_i).to eq(time.to_i)
      end
    end

    describe '#notes:user' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let(:notes) { 'some notes about a client' }
      let!(:rr) { ReportingRelationship.create(user: user, client: client, notes: notes) }

      it 'returns the relevant notes' do
        expect(client.notes(user: user)).to eq(notes)
      end
    end

    describe '#active:user' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let!(:rr) { ReportingRelationship.create(user: user, client: client, active: false) }

      it 'returns the relevant value' do
        expect(client.active(user: user)).to eq(false)
      end
    end

    describe '#has_message_error:user' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let!(:rr) { ReportingRelationship.create(user: user, client: client, has_message_error: true) }

      it 'returns the relevant value' do
        expect(client.has_message_error(user: user)).to eq(true)
      end
    end

    describe '#has_unread_messages:user' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let!(:rr) { ReportingRelationship.create(user: user, client: client, has_unread_messages: true) }

      it 'returns the relevant value' do
        expect(client.has_unread_messages(user: user)).to eq(true)
      end
    end

    describe '#timestamp' do
      let(:user) { create :user }
      let(:client) { create :client, first_name: 'Lorraine', last_name: 'Collins' }
      let(:time) { 1.day.ago }
      let!(:rr) { ReportingRelationship.create(user: user, client: client, created_at: time) }

      it 'returns the correct time' do
        expect(client.timestamp(user: user)).to eq(time.to_i)
      end

      context 'reporting_relationship.last_contacted_at is set' do
        let!(:rr) do
          ReportingRelationship.create(
            user: user,
            client: client,
            last_contacted_at: time,
            created_at: time.yesterday
          )
        end

        it 'uses the last_contacted_at date' do
          expect(client.timestamp(user: user)).to eq(time.to_i)
        end
      end
    end
  end

  describe 'normalizing' do
    let(:dept) { create :department, phone_number: department_number }
    let(:user) { create :user, department: dept, phone_number: user_number }
    let(:client) { create :client, user: user, phone_number: client_number }
    let(:normalized_client_number) { 'fake_client_number_normal' }

    before do
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: department_number)
        .and_return('fake_normal_number')
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: user_number)
        .and_return('fake_normal_number')
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: client_number)
        .and_return(normalized_client_number)
    end

    it 'formats the phone number' do
      expect(client.reload.phone_number).to eq(normalized_client_number)
    end
  end

  describe 'validations' do
    let(:user) { create :user, phone_number: user_number, department: nil }

    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number) }

    it 'validates correctness of phone_number' do
      bad_number = '(212) 55-5236'
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: user_number)
        .and_return('fake_normal_number')

      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: bad_number)
        .and_raise(SMSService::NumberNotFound)

      new_client = build(:client, phone_number: bad_number, user: user)
      expect(new_client.valid?).to eq(false)
      expect(new_client.errors.keys).to contain_exactly(:phone_number)
    end

    it 'does not validate correctness of phone_number if phone number unchanged' do
      client = create :client, user: user, phone_number: client_number
      allow(SMSService.instance).to receive(:number_lookup)
      client.update!(first_name: 'some other name')
      expect(SMSService.instance).to_not have_received(:number_lookup)
    end
  end

  describe '#analytics_tracker_data' do
    it 'shows data about the client' do
      client = create :client, id: 4

      expect(client.analytics_tracker_data).to include(client_id: 4)
    end
  end
end
