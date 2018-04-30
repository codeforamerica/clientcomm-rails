require 'rails_helper'

describe 'Tracking of message analytics events', type: :request do
  context 'GET#index' do
    it 'tracks a visit to the message index' do
      user = create :user
      sign_in user
      client = create :client, user: user
      rr = user.reporting_relationships.find_by(client: client)
      get reporting_relationship_path(rr)
      expect(response.code).to eq '200'

      expect_analytics_events('client_messages_view' => {
                                'client_id' => client.id,
                                'has_unread_messages' => false,
                                'hours_since_contact' => 0,
                                'messages_all_count' => 0,
                                'messages_received_count' => 0,
                                'messages_sent_count' => 0,
                                'messages_attachments_count' => 0
                              })
    end
  end
end
