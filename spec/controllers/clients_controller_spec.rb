require 'rails_helper'

RSpec.describe ClientsController, type: :controller do
  describe '#index' do
    it 'rejects unauthenticated user' do
      get :index
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end

    it 'allows authenicated user' do
      user = create :user
      sign_in user
      get :index
      expect(response.code).to eq '200'
      expect(response).to render_template 'index'
    end

    it "returns only authenticated user's clients" do
      # one user with two clients
      userone = create :user
      create :client, :user => userone, :first_name => 'Elísa'
      create :client, :user => userone, :first_name => 'Helena'
      # another user with one client
      usertwo = create :user
      create :client, :user => usertwo, :first_name => 'Unnsteinn'
      # sign in as the first user
      sign_in userone
      get :index
      expect(response.code).to eq '200'
      # should only see the first user's clients
      expect(assigns[:clients].map(&:first_name)).to match_array %w[Elísa Helena]
    end

  end
end
