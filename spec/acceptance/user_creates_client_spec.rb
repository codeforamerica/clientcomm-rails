require "rails_helper"

feature "User creates client" do
  scenario "successfully" do
    visit root_path
    click_on "New client"
    fill_in "First name", with: "Colby"
    fill_in "Last name", with: "Rucker"
    select "November", from: "client_birth_date_2i"
    select "7", from: "client_birth_date_3i"
    select "1982", from: "client_birth_date_1i"
    fill_in "Phone number", with: "2435551212"
    click_on "Save new client"
    expect(page).to have_css '.clients li', text: "Colby Rucker"
  end
end
