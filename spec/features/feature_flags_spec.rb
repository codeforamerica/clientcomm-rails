require 'rails_helper'

feature 'feature flags' do

  describe 'signups' do
    before do
      @signups_value = ENV['ALLOW_SIGNUPS']
    end

    after do
      ENV['ALLOW_SIGNUPS'] = @signups_values
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
end
