require 'rails_helper'

feature 'Client status banner' do
  let(:message_body) { 'Close to our bows, strange forms in the water darted hither and thither before us.' }
  let(:department) { create :department }
  let!(:client_status) { create :client_status, name: 'Active', followup_date: 30, department: department }
  let!(:user) { create :user, department: department }
  let!(:recent_clients) { create_list :client, 2 }
  let!(:older_clients) { create_list :client, 3 }

  before do
    login_as(user, :scope => :user)

    recent_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: client_status,
        last_contacted_at: Time.now - 5.days
      )
    end

    older_clients.each do |client|
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: client_status,
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

      recent_clients.each do |client|
        rr = ReportingRelationship.find_by(client: client, user: user)
        expect(find("#mass_message_reporting_relationships_#{rr.id}")['checked']).to eq(false)
      end

      older_clients.each do |client|
        rr = ReportingRelationship.find_by(client: client, user: user)
        expect(find("#mass_message_reporting_relationships_#{rr.id}")['checked']).to eq(true)
      end
    end

    step 'send a message' do
      fill_in 'Your message', with: message_body
      click_on 'Send'

      expect(page).to have_current_path(clients_path)
      expect(page).to have_content I18n.t('flash.notices.mass_message.sent')

      expect(Message.where(body: message_body).count).to eq older_clients.count
      older_clients.each do |client|
        expect(Client.find_by(phone_number: client.phone_number).messages.last.body).to eq message_body
      end
    end
  end
end
