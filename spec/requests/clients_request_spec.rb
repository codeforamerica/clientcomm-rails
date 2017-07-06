require 'rails_helper'

describe 'Access to clients methods', type: :request do
  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      get clients_path
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'authenticated' do
    let(:user) { create :user }

    before do
      sign_in user
    end

    describe 'POST#create' do
      before do
        create_client client
      end

      context 'receives valid client parameters' do
        let(:client) { build(:client) }

        it 'creates a client' do
          expect(response.code).to eq '302'
          expect(response).to redirect_to clients_path
          expect(Client.count).to eq 1
        end

        it 'tracks the creation of a new client' do
          created_client = Client.find_by(phone_number: client.phone_number)

          expect_analytics_events(
              {
                  'client_create_success' => {
                      'client_id' => created_client.id,
                      'has_client_dob' => true
                  }
              }
          )
        end
      end

      context 'receives invalid client parameters' do
        let(:client) { build(:client, last_name: nil) }

        it 'renders new with validation errors' do
          expect(response.code).to eq '200'
          expect(Client.count).to eq 0
          expect(client.valid?).to be_falsey
          expect([:last_name]).to eq client.errors.keys
        end
      end
    end
  end
end
