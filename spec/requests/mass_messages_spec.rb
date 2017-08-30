require 'rails_helper'

describe 'Mass messages requests', type: :request, active_job: true do
  let(:user) { create :user }
  let!(:client_1) { create :client, user: user }
  let!(:client_2) { create :client, user: user }
  let!(:client_3) { create :client, user: user }
  let(:message_body) { 'hello this is message one' }

  before do
    sign_in user
  end

  describe 'POST#create' do
    it 'sends message to multiple clients' do
      post_params = {
        mass_message: {
          message: message_body,
          clients: ["", client_1.id, client_3.id]
        }
      }

      post mass_messages_path, params: post_params

      expect(user.messages.count).to eq 2
      expect(client_1.messages.count).to eq 1
      expect(client_1.messages.first.body).to eq message_body
      expect(client_2.messages.count).to eq 0
      expect(client_3.messages.count).to eq 1
      expect(client_3.messages.first.body).to eq message_body
    end
  end
end
