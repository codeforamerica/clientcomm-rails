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
          'unread_messages' => false,
          'unread_messages_count' => 0,
          'clients_count' => 0
        }
      })
    end

    it 'tracks a visit to the client index with clients and messages' do
      user = create :user
      sign_in user
      clientone = create_client build(:client, user: user)
      clienttwo = create_client build(:client, user: user)
      create :message, user: user, client: clientone, inbound: true
      create :message, user: user, client: clientone, inbound: true
      create :message, user: user, client: clienttwo, inbound: true
      get clients_path
      expect(response.code).to eq '200'
      expect_analytics_events({
        'client_list_view' => {
          'unread_messages' => true,
          'unread_messages_count' => 3,
          'clients_count' => 2
        }
      })
    end
  
  
  end
end
