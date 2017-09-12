require 'rails_helper'

describe 'Root Paths', type: :request do
  subject { get root_path }

  context 'Unauthenticated' do
    it 'shows the login page' do
      subject
      expect(response.body).to include('Log in')
    end
  end

  context 'Disabled' do
    let(:inactive_user) { create :user, active: false }

    it 'shows the login page' do
      sign_in inactive_user

      subject

      expect(response.body).to include('Log in')
      expect(response.body).to include('Sorry, this account has been disabled.')
    end
  end

  context 'Authenticated' do
    let(:user) { create :user }
    before do
      sign_in user
    end

    it 'shows the clients index page' do
      subject
      expect(response.body).to include('My clients')
    end
  end
end
