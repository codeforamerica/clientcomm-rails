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
    it 'rejects unauthenticated user' do
      client = build :client
      create_client client
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
      expect(Client.count()).to eq 0
    end

    it 'allows authenticated user' do
      user = create :user
      sign_in user
      client = build :client
      create_client client
      expect(response.code).to eq '302'
      expect(response).to redirect_to clients_path
      expect(Client.count()).to eq 1
    end
  end
end
