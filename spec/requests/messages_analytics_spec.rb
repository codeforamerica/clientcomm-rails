require 'rails_helper'

describe 'Tracking of message analytics events', type: :request do
  context 'GET#index' do
    it 'tracks a visit to the message index' do
      clientone = nil
      travel_to 3.hours.ago do
        user = create :user
        sign_in user
        clientone = create_client build(:client)
        msgone = create :message, user: user, client: clientone, inbound: true
        msgtwo = create :message, user: user, client: clientone, inbound: true
        create :message, user: user, client: clientone, inbound: true
        create :message, user: user, client: clientone, inbound: false
        create :message, user: user, client: clientone, inbound: true
        create :attachment, message: msgone
        create :attachment, message: msgone
        create :attachment, message: msgtwo
      end
      get client_messages_path clientone
      expect(response.code).to eq '200'

      expect_analytics_events({
        'client_messages_view' => {
          'client_id' => clientone.id,
          'has_unread_messages' => true,
          'hours_since_contact' => 3,
          'messages_all_count' => 5,
          'messages_received_count' => 4,
          'messages_sent_count' => 1,
          'messages_attachments_count' => 3
        }
      })
    end
  end
end
