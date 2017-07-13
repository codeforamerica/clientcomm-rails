require 'rails_helper'

describe 'Tracking of client analytics events', type: :request do
  context 'GET#index' do
    it 'tracks a visit to the client index with no clients or messages' do
      user = create :user
      sign_in user
      get clients_path
      expect(response.code).to eq '200'

      expect_analytics_events({
        'clients_view' => {
          'has_unread_messages' => false,
          'unread_messages_count' => 0,
          'clients_count' => 0
        }
      })
    end

    it 'tracks a visit to the client index with clients and messages' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      clienttwo = create_client build(:client)
      create :message, user: user, client: clientone, inbound: true
      create :message, user: user, client: clientone, inbound: true
      create :message, user: user, client: clienttwo, inbound: true
      get clients_path
      expect(response.code).to eq '200'
      expect_analytics_events({
        'clients_view' => {
          'has_unread_messages' => true,
          'unread_messages_count' => 3,
          'clients_count' => 2
        }
      })
    end
  end

  context 'GET#new' do
    it 'tracks a visit to the create client form' do
      user = create :user
      sign_in user
      get new_client_path
      expect(response.code).to eq '200'
      expect_analytics_events_happened('client_create_view')
    end
  end

  context 'GET#edit' do
    it 'tracks a visit to the edit client form' do
      userone = create :user
      clientone = create :client, user: userone
      sign_in userone
      get edit_client_path(clientone.id)
      expect(response.code).to eq '200'
      expect_analytics_events_happened('client_edit_view')
    end
  end

  context 'PATCH#update' do
    it 'tracks the updating of a client' do
      userone = create :user
      clientone = create :client, user: userone
      sign_in userone
      # we'll patch clientone to match clientedit
      clientedit = build :client, user: userone
      edit_client clientone.id, clientedit
      expect(response.code).to eq '302'
      expect_analytics_events({
        'client_edit_success' => {
          'client_id' => clientone.id
        }
      })
    end
  end
end
