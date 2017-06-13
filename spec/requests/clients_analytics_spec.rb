require 'rails_helper'

describe 'Tracking of analytics events', type: :request do
  context 'GET#index' do
    it 'tracks a visit to the client index' do
      user = create :user
      sign_in user
      get clients_path
      expect(response.code).to eq '200'
      expect_analytics_events({
        'client_list_view' => {
          'unread_messages' => false,
          'unread_messages_count' => 0
        }
      })
    end
  end
end
