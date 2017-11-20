require 'rails_helper'

user_full_name = 'Tesfalem Medhanie'
user_email = 'me@example.com'
user_password = 'paassswoord'

feature "user wants to log in, check clients, and log out, so they", :js do
  let(:existing_user) { create :user, full_name: user_full_name, email: user_email, password: user_password, dept_phone_number: '+17605556661' }

  specify do
    step 'when an existing user logs in' do
      login_as(existing_user, scope: :user)
    end

    step 'log out and are redirected to login form' do
      visit root_path
      click_on 'Account'
      expect(page).to have_text "Log out #{existing_user.full_name}"
      click_on "Log out #{existing_user.full_name}"
      expect(page).to have_text 'Log in'
      expect(page).to have_current_path(root_path)
    end

    step 'log in and are redirected to client list' do
      fill_in 'Email', with: user_email
      fill_in 'Password', with: user_password
      click_on 'Sign in'
      expect(page).to have_text 'My clients'
      expect(page).to have_current_path(root_path)
      expect(page).to have_text('(760) 555-6661')
    end
  end
end
