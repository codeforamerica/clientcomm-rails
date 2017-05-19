require "rails_helper"

user_full_name = 'Tesfalem Medhanie'
user_email = 'me@example.com'
user_password = 'paassswoord'

feature "user wants to log in, check clients, and log out, so they" do
  specify do
    step "go to the front page and are directed to the login form" do
      visit root_path
      expect(page).to have_text "Log in"
      expect(page).to have_current_path(new_user_session_path)
    end

    step "click on the sign up button and are directed to the sign up form" do
      click_on "Sign up"
      expect(page).to have_text "Confirm password"
      expect(page).to have_current_path(new_user_registration_path)
    end

    step "fill out and submit the form; then are redirected to client list" do
      fill_in "Full name", with: user_full_name
      fill_in "Email", with: user_email
      fill_in "Password", with: user_password
      fill_in "Confirm password", with: user_password
      click_on "Sign up"
      expect(page).to have_text "My clients"
      expect(page).to have_text user_full_name
      expect(page).to have_current_path(root_path)
    end

    step "log out and are redirected to login form" do
      click_on "Sign out"
      expect(page).to have_text "Log in"
      expect(page).to have_current_path(new_user_session_path)
    end

    step "log in and are redirected to client list" do
      fill_in "Email", with: user_email
      fill_in "Password", with: user_password
      click_on "Sign in"
      expect(page).to have_text "My clients"
      expect(page).to have_text user_full_name
      expect(page).to have_current_path(root_path)
    end

  end
end

feature "user who doesn't enter full name" do
  scenario "sees email address in header" do
      visit new_user_registration_path
      fill_in "Email", with: user_email
      fill_in "Password", with: user_password
      fill_in "Confirm password", with: user_password
      click_on "Sign up"
      expect(page).to have_text "My clients"
      expect(page).to have_text user_email
      expect(page).to have_current_path(root_path)
  end
end
