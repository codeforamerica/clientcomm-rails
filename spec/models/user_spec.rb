require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create :user }
  let!(:client) { create :client, :user => user }
  let!(:message) { create :message, :user => user, :client => client}

  describe 'validations' do
    it {
      should validate_presence_of :full_name
    }

    it 'validates uniqueness of desk_phone_number' do
      existing_user = create(:user)
      new_user = build(:user, desk_phone_number: existing_user.desk_phone_number)
      expect(new_user.valid?).to eq(false)
      expect(new_user.errors.keys).to contain_exactly(:desk_phone_number)
    end
  end

  describe 'relationship to client' do
    it 'has a client' do
      expect(client.user).to eq(user)
    end
  end

  describe 'relationship to message' do
    it 'has a message' do
      expect(message.user).to eq(user)
    end
  end
end
