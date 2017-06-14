require 'rails_helper'

describe 'Tracking of message analytics events', type: :request do
  context 'GET#index' do
    it 'tracks a visit to the message index' do
      clientone = nil
      travel_to 3.hours.ago do
        user = create :user
        sign_in user
        clientone = create_client build(:client)
        create :message, user: user, client: clientone, inbound: true
        create :message, user: user, client: clientone, inbound: true
        create :message, user: user, client: clientone, inbound: true
        create :message, user: user, client: clientone, inbound: false
        create :message, user: user, client: clientone, inbound: true
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
          'messages_sent_count' => 1
        }
      })
    end
  end

  context 'POST#create' do
    it 'tracks a new message submission' do
      user = create :user
      sign_in user
      clientone = create_client build(:client)
      messageone = create(
        :message,
        user: user,
        client: clientone,
        inbound: true
      )

      expect_analytics_events({
        'message_send' => {
          'client_id' => clientone.id,
          'message_id' => messageone.id,
          'message_length' => messageone.body.length
        }
      })
    end
  end
end
