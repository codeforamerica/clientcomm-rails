require 'rails_helper'

describe 'batch import', type: :request do
  let(:user) { create :user }
  let(:user_2) { create :user }
  let(:clients) { create_list :client, 5, user: user }

  before do
    admin_user = create :admin_user
    login_as admin_user, scope: :admin_user
  end

  describe 'POST#batch_transfer' do

    before do
      clients.each do |client|
        create_list :message, 2, client: client, user: user, send_at: Time.now + 1.day
      end
    end

    it 'transfers clients and their scheduled messages' do
      params = {
        batch_action: :transfer,
        batch_action_inputs: { user: user_2.id }.to_json,
        collection_selection: clients.map(&:id)
      }

      post '/admin/clients/batch_action', params: params
      clients.each do |client|
        expect(client.reload.user).to eq(user_2)
        expect(user_2.messages.scheduled).to include(*client.messages.scheduled)
      end
    end
  end

  describe 'PUT#update' do

    before do
      create_list :message, 5, client: clients.first, user: user, send_at: Time.now + 1.day
    end

    it 'transfers scheduled messages' do
      client = clients.first

      put admin_client_path(client), params: {
        client: {
          user_id: user_2.id
        }
      }

      expect(client.reload.user).to eq(user_2)
      expect(user_2.messages.scheduled).to include(*client.messages.scheduled)
    end
  end
end
