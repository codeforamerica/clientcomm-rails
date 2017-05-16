require "rails_helper"

feature "user wants to use the site, so they" do
  specify do
    user_email = 'me@example.com'
    user_password = 'paassswoord'

    step "go to the front page and are directed to the login form" do
      visit root_path
      expect(current_path).to eq new_user_session_path
      expect(page).to have_text "Log in"
    end

    step "click on the sign up button and are directed to the sign up form" do
      click_on "Sign up"
      expect(current_path).to eq new_user_registration_path
      expect(page).to have_text "Confirm password"
    end

    step "fill out and submit the form" do
      fill_in "Email", with: user_email
      fill_in "Password", with: user_password
      fill_in "Confirm password", with: user_password
      click_on "Sign up"
      expect(page).to have_text "My clients"
      expect(page).to have_text user_email
    end

    step "log out and be redirected to the login form" do
      click_on "Sign out"
      expect(current_path).to eq new_user_session_path
      expect(page).to have_text "Log in"
    end

  end
end
