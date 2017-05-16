require "rails_helper"

feature "logged-out user visits create client page" do
  scenario "and is redirected to the login form" do
    visit new_client_path
    expect(current_path).to eq new_user_session_path
    expect(page).to have_text "Log in"
  end
end

feature "User creates client" do
  scenario "successfully" do
    user = FactoryGirl.create(:user)
    login_as(user, :scope => :user)
    visit root_path
    click_on "New client"
    fill_in "First name", with: "Colby"
    fill_in "Last name", with: "Rucker"
    select "November", from: "client_birth_date_2i"
    select "7", from: "client_birth_date_3i"
    select "1982", from: "client_birth_date_1i"
    fill_in "Phone number", with: "2435551212"
    expect(current_path).to eq new_client_path
    click_on "Save new client"
    expect(page).to have_css '.data-table td', text: "Colby Rucker"
    expect(current_path).to eq clients_path
  end
end
