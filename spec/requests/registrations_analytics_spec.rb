require 'rails_helper'

describe 'RegistrationsController', type: :request do
  describe 'GET#new' do
    it 'redirects to the sign in page' do
      get new_user_registration_path
      expect(response).to redirect_to '/users/sign_in'
    end
  end

  describe 'POST#create' do
    it 'redirects to the sign in page' do
      post user_registration_path
      expect(response).to redirect_to '/users/sign_in'
      expect(flash[:notice]).to include('Contact an administrator')
    end
  end
end
