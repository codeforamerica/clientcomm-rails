require "rails_helper"

user_full_name = 'Tesfalem Medhanie'
user_email = 'me@example.com'
user_password = 'paassswoord'

feature "user wants to log in, check clients, and log out, so they" do
  specify do
    step 'when an existing user logs in' do
      existing_user = create :user
      login_as(existing_user, scope: :user)
    end

    step 'when the user invites a new user' do
      visit new_user_invitation_path

      fill_in 'user_email', with: user_email

      click_on 'Send an invitation'

      expect(page).to have_content "An invitation email has been sent to #{user_email}."
      click_on 'Sign out'
    end

    step 'then the new user should receive an invitation email' do
      mail = ActionMailer::Base.deliveries.last
      expect(mail['to'].to_s).to eq user_email
    end

    step 'when the new user navigates to the invitation page' do
      invitation_token = invitation_token_from_email(ActionMailer::Base.deliveries.last)

      visit accept_user_invitation_path(invitation_token: invitation_token)
      expect(page).to have_text 'Sign up'
    end

    step 'when the new user completes the form; then are redirected to client list' do
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
      expect(page).to have_current_path(root_path)
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

def invitation_token_from_email(email)
  html_string = email.html_part.to_s
  parsed_html = Nokogiri::HTML(html_string)
  invitation_link_element = parsed_html.css('a').first
  invitation_url = invitation_link_element[:href]
  invitation_url.split('invitation_token=')[1]
end
