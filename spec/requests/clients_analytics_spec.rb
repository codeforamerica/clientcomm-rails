require 'rails_helper'

describe 'Tracking of analytics events', type: :request do
  context 'GET#index' do
    it 'tracks a visit to the client index with no clients or messages' do
      user = create :user
      sign_in user
      get clients_path
      expect(response.code).to eq '200'

      expect_analytics_events({
        'client_list_view' => {
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
        'client_list_view' => {
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
      expect_analytics_events('client_create_view')
    end
  end

  context 'POST#new' do
    it 'tracks the creation of a new client' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      expect(response.code).to eq '302'
      expect_analytics_events({
        'client_create_success' => {
          'client_id' => clientone.id,
          'has_client_dob' => true
        }
      })
    end
  end
end
