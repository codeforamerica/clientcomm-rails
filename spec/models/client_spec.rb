require 'rails_helper'

RSpec.describe Client, type: :model do
  let!(:user) { create :user }
  let!(:client) { create :client, :user => user }
  let!(:message) { create :message, :user => user, :client => client}

  describe 'relationship to user' do
    it 'belongs to a user' do
      expect(client.user).to eq(user)
    end
  end

  describe 'relationship to message' do
    it 'has a message' do
      expect(message.client).to eq(client)
    end
  end

  describe 'display' do
    it 'formats full name' do
      expect(client.full_name).to eq(client.first_name + " " + client.last_name)
    end
  end

end
