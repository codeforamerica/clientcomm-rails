require 'rails_helper'

describe 'Tracking of registration analytics events', type: :request do
  context 'GET#new' do
    it 'tracks a visit to the sign up page' do
      get new_user_registration_path
      expect(response).to redirect_to '/users/sign_in'
    end
  end
end
