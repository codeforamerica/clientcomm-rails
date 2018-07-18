require 'rails_helper'

feature 'Client status banner', active_job: true do
  let(:message_body) { 'Close to our bows, strange forms in the water darted hither and thither before us.' }
  let(:department) { create :department }
  let!(:user) { create :user, department: department }
  let!(:recent_clients) { create_list :client, 2 }
  let!(:older_clients) { create_list :client, 3 }
  let(:active) { 'Active' }
  let(:waiting) { 'Waiting' }
  let(:moving) { 'Moving' }

  before do
    create :client_status, name: active, followup_date: 30, department: department
    create :client_status, name: waiting, department: department
    create :client_status, name: moving, department: department
    login_as(user, scope: :user)

    recent_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: active),
        last_contacted_at: Time.zone.now - 5.days
      )
    end

    older_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: active),
        last_contacted_at: Time.zone.now - 26.days
      )
    end
    waiting_clients = create_list :client, 5
    waiting_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: waiting),
        last_contacted_at: Time.zone.now
      )
    end
    moving_clients = create_list :client, 5
    moving_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: moving),
        last_contacted_at: Time.zone.now
      )
    end
  end

  scenario 'user sees banner; sorts and messages clients', js: true do
    step 'view banner on clients page' do
      visit clients_path
      expect(page).to have_css '.status-banner-container', text: 'You have 3 active clients due for follow up.'
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

      recent_clients.each do |client|
        rr = ReportingRelationship.find_by(client: client, user: user)
        expect(find("#mass_message_reporting_relationships_#{rr.id}")['checked']).to eq(nil)
      end

      older_clients.each do |client|
        rr = ReportingRelationship.find_by(client: client, user: user)
        expect(find("#mass_message_reporting_relationships_#{rr.id}")['checked']).to eq('true')
      end
    end

    step 'send a message' do
      fill_in 'Your message', with: message_body
      perform_enqueued_jobs do
        click_on 'Send'
      end

      expect(page).to have_current_path(clients_path)
      expect(page).to have_content I18n.t('flash.notices.mass_message.sent')
      expect(page).to_not have_css '.status-banner-container', text: /You have \d+ active client[s|] due for follow up./

      expect(Message.where(body: message_body).count).to eq older_clients.count
      older_clients.each do |client|
        expect(Client.find_by(phone_number: client.phone_number).messages.last.body).to eq message_body
      end
    end
  end
end
