require 'rails_helper'

describe 'Messages', type: :request do
  context 'GET#index' do
    it 'marks all messages read when index loaded' do
      user = create :user
      sign_in user
      client = create_client build(:client, user: user)
      message = create :message, user: user, client: client, inbound: true

      # when we visit the messages path, it should mark the message read
      expect { get client_messages_path(client) }
        .to change { message.reload.read? }
        .from(false)
        .to(true)
    end
  end
end
