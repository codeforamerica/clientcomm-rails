require 'rails_helper'

describe 'Messages requests', type: :request, active_job: true do
  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      client = create(:client)

      get client_scheduled_messages_index_path(client)

      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'authenticated' do
    let!(:user) { create :user }
    let!(:client) { create :client, user: user }
    let(:message_one_body) { 'hello this is message one' }
    let(:message_two_body) { 'hello this is message two' }
    let!(:message_one) { create :message, user: user, client: client, body: message_one_body, send_at: Time.now.tomorrow }
    let!(:message_two) { create :message, user: user, client: client, body: message_two_body, send_at: Time.now.tomorrow + 1.hour }

    before do
      sign_in user
    end

    describe 'GET#index' do
      it 'displays list of scheduled messages' do
        get client_scheduled_messages_index_path(client)

        expect(response.body).to include message_one_body
        expect(response.body).to include message_two_body

        expect_most_recent_analytics_event(
          {
            'client_scheduled_messages_view' => {
              'messages_scheduled_count' => 2
            }
          }
        )
      end
    end
  end
end
