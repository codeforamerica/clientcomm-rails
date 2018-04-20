require 'rails_helper'

feature 'Client status banner' do
  let(:active) { 'Active' }
  let(:waiting) { 'Waiting' }
  let(:moving) { 'Moving' }

  before do
    department = create :department
    create :client_status, name: active, followup_date: 30, department: department
    create :client_status, name: waiting, department: department
    create :client_status, name: moving, department: department

    user = create :user, department: department
    login_as(user, :scope => :user)

    recent_clients = create_list :client, 2
    recent_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: active),
        last_contacted_at: Time.now - 5.days
      )
    end
    older_clients = create_list :client, 3
    older_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: active),
        last_contacted_at: Time.now - 26.days
      )
    end
    waiting_clients = create_list :client, 5
    waiting_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: waiting),
        last_contacted_at: Time.now
      )
    end
    moving_clients = create_list :client, 5
    moving_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: moving),
        last_contacted_at: Time.now
      )
    end
  end

  scenario 'user sees banner; sorts and messages clients', js: true do
    step 'view banner on clients page' do
      visit clients_path

      expect(page).to have_content 'You have 3 active clients due for follow up'
    end

    step 'sorts list by status when Status header is clicked' do
      find('th', text: 'Status').click
      expect(page).to have_css('tr:first-child', text: active)
      expect(page).to have_css('tr:last-child', text: waiting)
    end

    step 'reverses the sort order when the Status header is clicked again' do
      find('th', text: 'Status').click
      expect(page).to have_css('tr:first-child', text: waiting)
      expect(page).to have_css('tr:last-child', text: active)
    end

    step 'click on button and go to mass message page' do
      click_on 'Message them'

      expect(page).to have_current_path(new_mass_message_path, only_path: true)
    end
  end
end
