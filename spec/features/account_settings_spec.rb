require "rails_helper"

user_full_name = 'Tesfalem Medhanie'
user_email = 'me@example.com'
user_password = 'paassswoord'

feature "user wants to update their account settings, so they" do
  specify do
    step 'user logs in' do
      existing_user = create :user, full_name: user_full_name, email: user_email, password: user_password
      login_as(existing_user, scope: :user)
    end

    step "clicks on account button in navbar" do
      visit root_path
      click_on "Account"
      expect(page).to have_text "Account settings"
    end

    step "clicks on account menu item" do
      click_on "Account settings"
      expect(page).to have_text "Edit account settings"
      expect(page).to have_text "Change password"
    end
  end
end
