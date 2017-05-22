require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create :user }
  let!(:client) { create :client, :user => user }
  let!(:message) { create :message, :user => user, :client => client}

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
