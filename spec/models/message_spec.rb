require 'rails_helper'

RSpec.describe Message, type: :model do
  let!(:user) { create :user }
  let!(:client) { create :client, :user => user }
  let!(:message) { create :message, :user => user, :client => client}

  describe 'relationship to client' do
    it 'belings to a client' do
      expect(message.client).to eq(client)
    end
  end

  describe 'relationship to user' do
    it 'belings to a user' do
      expect(message.user).to eq(user)
    end
  end
end
