require "rails_helper"

feature "user visits clients page" do
  scenario "successfully" do
    visit root_path

    expect(page).to have_css 'h1', text: 'Clients'
  end
end
