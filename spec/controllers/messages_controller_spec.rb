require 'rails_helper'

describe MessagesController do
  let(:user) {create(:user)}
  let(:client) {create(:client, user: user)}

  before do
    sign_in user
  end

  describe 'POST#create' do
    let(:message_text) { 'Some message body' }

    it 'tracks a new message submission' do
      post :create, format: :js, params: {
          message: { body: message_text },
          client_id: client.id
      }

      message = Message.find_by(body: message_text)

      expect_analytics_events(
          {
              'message_send' => {
                  'client_id' => client.id,
                  'message_id' => message.id,
                  'message_length' => message.body.length
              }
          })
    end
  end
end
