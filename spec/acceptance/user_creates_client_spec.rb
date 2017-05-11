require "rails_helper"

feature "User creates client" do
    scenario "successfully" do
        visit root_path
        click_on "Add New Client"
        fill_in "First Name", with: "Colby"
        fill_in "Last Name", with: "Rucker"
        fill_in "Day", with: "7"
        fill_in "Month", with: "11"
        fill_in "Year", with: "1982"
        fill_in "Phone Number", with: "12435551212"
        click_on "Save New Client"

        expect(page).to have_css '.clients li', text: "Colby Rucker"
    end
end
