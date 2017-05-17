require "rails_helper"

feature "logged-out user visits clients page" do
  scenario "and is redirected to the login form" do
    visit clients_path
    expect(page).to have_text "Log in"
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature "logged-in user visits clients page" do
  scenario "successfully" do
    myuser = create :user
    login(myuser)
  end
end
