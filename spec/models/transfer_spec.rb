require 'rails_helper'

RSpec.describe Transfer, type: :model do
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :client_id }

  describe '#apply' do
    let(:department) { create :department }
    let(:user) { create :user, department: department }
    let(:transfer_user) { create :user, department: department }
    let!(:client) { create :client, user: user }

    it 'transfers client from user to user' do
      transfer = Transfer.new user_id: transfer_user.id, client_id: client.id

      expect(user.clients.active).to include client
      expect(transfer_user.clients.active).to_not include client

      transfer.apply

      expect(user.clients.active).to_not include client
      expect(transfer_user.clients.active).to include client
    end
  end
end
