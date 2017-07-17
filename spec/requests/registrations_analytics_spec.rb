require 'rails_helper'

describe 'Tracking of registration analytics events', type: :request do
  context 'GET#new' do
    it 'tracks a visit to the sign up page' do
      get new_user_registration_path
      expect(response).to redirect_to '/users/sign_in'
    end
  end

  context 'POST#resource' do
    it 'tracks a user successfully creating an account' do
      userone = build :user
      create_user userone
      expect_analytics_events_happened('signup_success')
    end

    it 'tracks a user erroring when trying to create an account' do
      # an empty email field should error
      userone = build :user, email: ""
      create_user userone
      expect_analytics_events_happened('signup_error')
    end
  end
end
