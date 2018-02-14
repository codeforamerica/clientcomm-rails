require 'rails_helper'

describe Department, type: :model do
  it { should have_many :users }
  it { should have_many :reports }
  it { should belong_to :unclaimed_user }

  describe 'validations' do
    it 'validates correctness of phone_number' do
      bad_number = '(212) 55-5236'
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: bad_number)
        .and_raise(SMSService::NumberNotFound)

      new_dept = build(:department, phone_number: bad_number)
      expect(new_dept.valid?).to eq(false)
      expect(new_dept.errors.keys).to contain_exactly(:phone_number)
    end

    it 'does not validate correctness of phone_number if phone number unchanged' do
      dept = create :department
      expect(SMSService.instance).not_to receive(:number_lookup)
      dept.update!(name: 'some other name')
    end
  end

  describe 'normalizing' do
    let(:input_phone_number) { '(760) 555-7890' }
    let(:normalized_phone_number) { '+17605557890' }
    before do
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: input_phone_number)
        .and_return(normalized_phone_number)
    end

    subject { create :department, phone_number: input_phone_number }

    it 'formats the phone number' do
      expect(subject.reload.phone_number).to eq(normalized_phone_number)
    end
  end

  describe '#message_metrics' do
    let(:now) { Time.now }
    let(:department) { create :department }
    let(:emails) { [1, 2, 3].map { |n| "recipient#{n}@example.com" } }
    let(:user1) { create :user, email: 'user1@user1.com', department: department }
    let(:user2) { create :user, email: 'user2@user2.com', department: department }
    let!(:clients1) { create_list :client, 5, user: user1 }
    let!(:clients2) { create_list :client, 5, user: user2 }
    let(:inbound1_count) { 21 }
    let(:outbound1_count) { 55 }
    let(:inbound2_count) { 34 }
    let(:outbound2_count) { 89 }
    let!(:transfers1) { create_list :message, 2, send_at: now - 1.day, transfer_marker: true, user: user1, client: user1.clients.sample }
    let!(:messages_inbound1) { create_list :message, inbound1_count, send_at: now - 1.day, inbound: true, user: user1, client: user1.clients.sample }
    let!(:messages_outbound1) { create_list :message, outbound1_count, send_at: now - 2.days, inbound: false, user: user1, client: user1.clients.sample }
    let!(:transfers2) { create_list :message, 2, send_at: now - 1.day, transfer_marker: true, user: user2, client: user2.clients.sample }
    let!(:messages_inbound2) { create_list :message, inbound2_count, send_at: now - 3.days, inbound: true, user: user2, client: user2.clients.sample }
    let!(:messages_outbound2) { create_list :message, outbound2_count, send_at: now - 4.days, inbound: false, user: user2, client: user2.clients.sample }

    it 'returns accurate metrics' do
      metrics = department.message_metrics now
      expect(metrics.count).to eq 2
      expect(metrics).to include([user1.full_name, outbound1_count, inbound1_count, outbound1_count + inbound1_count])
      expect(metrics).to include([user2.full_name, outbound2_count, inbound2_count, outbound2_count + inbound2_count])
    end

    context 'scoping by date' do
      before do
        create :message, send_at: now + 2.days, user: user1, client: user1.clients.first
      end

      it 'scopes metrics by the date passed in' do
        metrics = department.message_metrics now
        expect(metrics.count).to eq 2
        expect(metrics).to include([user1.full_name, outbound1_count, inbound1_count, outbound1_count + inbound1_count])
        expect(metrics).to include([user2.full_name, outbound2_count, inbound2_count, outbound2_count + inbound2_count])
      end
    end
  end
end
