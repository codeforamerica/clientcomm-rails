require 'rails_helper'

RSpec.describe ClientsController, type: :controller do
  describe '#index' do
    it 'requires authenticated user' do
      get :index
      expect(response).to redirect_to new_user_session_path
    end

    it 'returns user clients' do
      user = create :user
      create :client, :user => user, :first_name => 'Alice'
      create :client, :user => user, :first_name => 'Bob'
      usertwo = create :user
      create :client, :user => usertwo, :first_name => 'Stan'
      sign_in user
      get :index
      expect(response.code).to eq "200"
      expect(assigns[:clients].map(&:first_name)).to match_array %w[Alice Bob]
    end

  end
end
