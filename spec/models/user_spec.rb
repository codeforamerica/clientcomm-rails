require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create :user }
  let!(:client) { create :client, :user => user }
  let!(:message) { create :message, :user => user, :client => client }

  it { should belong_to :department }
  it { should have_many(:clients).through(:reporting_relationships) }
  it { should have_many :messages }

  describe 'normalizing' do
    let(:input_phone_number) { '(760) 555-7890' }
    let(:normalized_phone_number) { '+17605557890' }

    it 'formats the phone number' do
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: input_phone_number)
        .and_return(normalized_phone_number)

      user = create :user, phone_number: input_phone_number, department: nil
      expect(user.reload.phone_number).to eq(normalized_phone_number)
    end
  end

  describe 'validations' do
    it { should validate_presence_of :full_name }

    it 'validates correctness of phone_number' do
      bad_number = '(212) 55-5236'
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: bad_number)
        .and_raise(SMSService::NumberNotFound)

      new_user = build(:user, phone_number: bad_number, department: nil)
      expect(new_user.valid?).to eq(false)
      expect(new_user.errors.keys).to contain_exactly(:phone_number)
    end

    it 'does not validate correctness of phone_number if phone number unchanged' do
      user = create :user
      allow(SMSService.instance).to receive(:number_lookup)
      user.update!(full_name: 'some other name')
      expect(SMSService.instance).to_not have_received(:number_lookup)
    end
  end

  describe 'scopes' do
    describe 'active' do
      let!(:user_active) { create :user }
      let!(:user_inactive) { create :user, active: false }

      it 'only returns users that are active' do
        expect(User.all.active).to include user_active
        expect(User.all.active).to_not include user_inactive
      end
    end
  end
end
