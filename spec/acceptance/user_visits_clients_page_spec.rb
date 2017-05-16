require "rails_helper"
require "pry"

feature "logged-out user visits clients page" do
  scenario "and is redirected to the login form" do
    visit clients_path
    expect(current_path).to eq new_user_session_path
    expect(page).to have_text "Log in"
  end
end

feature "logged-in user visits clients page" do
  scenario "successfully" do
    user = FactoryGirl.create(:user)
    login_as(user, :scope => :user)
    visit clients_path
    expect(page).to have_text "My clients"
    expect(current_path).to eq clients_path
  end
end
