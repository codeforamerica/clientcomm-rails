require 'rails_helper'

feature 'feature flags' do
  describe 'scheduled messages' do
    let(:user) { create :user }
    let(:client) { create(:client, user: user) }

    before do
      login_as(user, :scope => :user)
      @scheduled_messages_value = ENV['SCHEDULED_MESSAGES']
    end

    after do
      ENV['SCHEDULED_MESSAGES'] = @scheduled_messages_value
    end

    context 'enabled' do
      before do
        ENV['SCHEDULED_MESSAGES'] = 'true'
        visit client_messages_path(client)
      end

      it 'shows the send later button' do
        expect(page).to have_content 'Send later'
      end
    end

    context 'disabled' do
      before do
        ENV['SCHEDULED_MESSAGES'] = 'false'
        visit client_messages_path(client)
      end

      it 'shows the send later button' do
        expect(page).not_to have_content 'Send later'
      end
    end
  end

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
