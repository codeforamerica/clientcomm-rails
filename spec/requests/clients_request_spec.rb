require 'rails_helper'

describe 'Access to clients methods', type: :request do
  context 'GET#index' do
    it 'rejects unauthenticated user' do
      get clients_path
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end

    it 'allows authenticated user' do
      user = create :user
      sign_in user
      get clients_path
      expect(response.code).to eq '200'
    end
  end

  context 'GET#new' do
    it 'rejects unauthenticated user' do
      get new_client_path
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end

    it 'allows authenticated user' do
      user = create :user
      sign_in user
      get new_client_path
      expect(response.code).to eq '200'
    end
  end

  context 'POST#create' do
    context 'unauthenticated user' do
      let(:client) {build(:client)}

      before do
        create_client client
      end

      it 'rejects unauthenticated user' do
        expect(response.code).to eq '302'
        expect(response).to redirect_to new_user_session_path
        expect(Client.count).to eq 0
      end
    end

    context 'authenticated user' do
      before do
        user = create :user
        sign_in user

        create_client client
      end

      context 'valid client' do
        let(:client) { build(:client) }

        it 'creates a client' do
          expect(response.code).to eq '302'
          expect(response).to redirect_to clients_path
          expect(Client.count).to eq 1
        end
      end

      context 'invalid client' do
        let(:client) { build(:client, last_name: nil) }

        it 'renders new with validation errors' do
          expect(response.code).to eq '200'
          expect(Client.count).to eq 0
        end
      end
    end
  end
end
