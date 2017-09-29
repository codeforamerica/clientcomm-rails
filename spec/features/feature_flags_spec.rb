require 'rails_helper'

feature 'feature flags' do

  describe 'signups' do
    context 'disabled' do
      it 'redirects to the login page' do
        visit new_user_registration_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context 'enabled' do
      before do
        FeatureFlag.create!(flag: "allow_signups", enabled: true)
      end

      let(:user_email) { 'some@email.com' }
      let(:user_password) { 'a strong password' }

      it 'allows signups' do
        visit new_user_registration_path

        expect(page).to have_content('Sign up')

        fill_in 'Email', with: user_email
        fill_in 'Password', with: user_password
        fill_in 'Password confirmation', with: user_password

        click_on 'Sign up'

        expect(page).to have_text user_email
        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe 'mass messages' do
    let(:myuser) { create :user }

    before do
      login_as(myuser, :scope => :user)
    end

    context 'enabled' do
      before do
        FeatureFlag.create!(flag: "mass_messages", enabled: true)
      end

      it 'shows mass messages button' do
        visit clients_path
        expect(page).to have_content 'Mass message'
      end
    end

    context 'disabled' do
      it 'does not show mass messages button' do
        visit clients_path
        expect(page).not_to have_content 'Mass message'
      end
    end
  end

  describe 'templates' do
    let(:myuser) { create :user }
    let(:client) { create :client, user: myuser }

    before do
      login_as(myuser, :scope => :user)
    end

    context 'enabled' do
      before do
        FeatureFlag.create!(flag: "templates", enabled: true)
      end

      it 'shows templates button' do
        visit client_messages_path(client)
        expect(page).to have_css '#template-button'
      end
    end

    context 'disabled' do
      it 'does not show templates button' do
        visit client_messages_path(client)
        expect(page).not_to have_css '#template-button'
      end
    end
  end
end
