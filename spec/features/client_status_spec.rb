require 'rails_helper'

feature "Client status banner" do
  before do
    FeatureFlag.create!(flag: 'client_status', enabled: true)
    ClientStatus.create!(name: 'Active', followup_date: 30)

    user = create :user
    login_as(user, :scope => :user)

    create_list :client, 2, user: user, client_status: ClientStatus.find_by_name('Active'), last_contacted_at: Time.now - 5.days
    create_list :client, 3, user: user, client_status: ClientStatus.find_by_name('Active'), last_contacted_at: Time.now - 26.days
  end

  scenario "user sees banner and messages clients" do
    step "view banner on clients page" do
      visit clients_path

      expect(page).to have_content "You have 3 active clients due for follow up"

    end

    step "click on button and go to mass message page" do
      click_on "Message them"

      expect(page).to have_current_path(new_mass_message_path, only_path: true)
    end
  end
end
