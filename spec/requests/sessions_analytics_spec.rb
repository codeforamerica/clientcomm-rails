require 'rails_helper'

describe 'Tracking of session analytics events', type: :request do
  context 'GET#new' do
    it 'tracks a visit to the log in page' do
      get new_user_session_path
      expect(response.code).to eq '200'
      expect_analytics_events_happened('login_view')
    end
  end

  context 'POST#resource' do
    it 'tracks a user successfully logging in' do
      userone = create :user
      sign_in userone
      expect_analytics_events_happened('login_success')
    end

    it 'tracks a user erroring when trying to log in' do
      # an unsaved user shouldn't be able to log in
      userone = build :user
      sign_in userone
      expect_analytics_events_happened('login_error')
    end
  end
end
