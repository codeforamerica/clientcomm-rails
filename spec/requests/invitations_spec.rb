require 'rails_helper'

describe 'invitations', type: :request do
  context 'GET devise/invitations#new' do
    it 'tracks a visit to the sign up page' do
      sign_in(create(:user))

      get new_user_invitation_path
      expect(response.code).to eq '200'
      expect_analytics_events_happened('invite_view')
    end
  end
end
