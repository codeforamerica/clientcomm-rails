require 'rails_helper'

feature 'feature flags' do

  describe 'signups' do
    before do
      @signups_value = ENV['ALLOW_SIGNUPS']
    end

    after do
      ENV['ALLOW_SIGNUPS'] = @signups_value
    end

    context 'disabled' do
      before do
        ENV['ALLOW_SIGNUPS'] = 'false'
      end

      it 'redirects to the login page' do
        visit new_user_registration_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context 'enabled' do
      before do
        ENV['ALLOW_SIGNUPS'] = 'true'
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
      @mass_messages_value = ENV['MASS_MESSAGES']
    end

    after do
      ENV['MASS_MESSAGES'] = @mass_messages_value
    end

    before do
      login_as(myuser, :scope => :user)
    end

    context 'enabled' do
      before do
        ENV['MASS_MESSAGES'] = 'true'
      end

      it 'shows mass messages button' do
        visit clients_path
        expect(page).to have_content 'Mass message'
      end
    end

    context 'disabled' do
      before do
        ENV['MASS_MESSAGES'] = 'false'
      end

      it 'does not show mass messages button' do
        visit clients_path
        expect(page).not_to have_content 'Mass message'
      end
    end
  end
end
