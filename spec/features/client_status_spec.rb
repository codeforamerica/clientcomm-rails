require 'rails_helper'

feature 'Client status banner' do
  before do
    department = create :department
    create :client_status, name: 'Active', followup_date: 30, department: department

    user = create :user, department: department
    login_as(user, :scope => :user)

    recent_clients = create_list :client, 2
    recent_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: 'Active'),
        last_contacted_at: Time.now - 5.days
      )
    end
    older_clients = create_list :client, 3
    older_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: 'Active'),
        last_contacted_at: Time.now - 26.days
      )
    end
  end

  scenario 'user sees banner and messages clients' do
    step 'view banner on clients page' do
      visit clients_path

      expect(page).to have_content 'You have 3 active clients due for follow up'
    end

    step 'click on button and go to mass message page' do
      click_on 'Message them'

      expect(page).to have_current_path(new_mass_message_path, only_path: true)
    end
  end
end
