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
      should validate_presence_of(:birth_date)
    }

    it 'validates presence of phone_number' do
      client = Client.new(last_name: 'Last', birth_date: DateTime.now)
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

end
