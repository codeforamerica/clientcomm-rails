require 'rails_helper'

describe 'Tracking of user analytics events', type: :request do
  context 'GET#new' do
    it 'tracks a visit to the sign up page' do
      get new_user_registration_path
      expect(response.code).to eq '200'
      expect_analytics_events('signup_view')
    end
  end

  context 'POST#resource' do
    it 'tracks a user successfully creating an account' do
      userone = build :user
      create_user userone
      expect_analytics_events('signup_complete')
    end

    it 'tracks a user erroring when trying to create an account' do
      # an empty email field should error
      userone = build :user, email: ""
      create_user userone
      expect_analytics_events('signup_error')
    end
  end
end
