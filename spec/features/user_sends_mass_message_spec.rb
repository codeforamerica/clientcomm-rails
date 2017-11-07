require "rails_helper"

feature 'sending mass messages', active_job: true do
  let(:message_body) { 'You have an appointment tomorrow at 10am' }
  let(:long_message_body) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent aliquam consequat mauris id sollicitudin. Aenean nisi nibh, ullamcorper non justo ac, egestas amet.' }
  let(:user) { create :user }
  let!(:client_1) { build :client, first_name: 'a', last_name: 'a' }
  let!(:client_2) { build :client, first_name: 'b', last_name: 'b' }
  let!(:client_3) { build :client, first_name: 'c', last_name: 'c' }
  let!(:message) { build :message }

  before do
    FeatureFlag.create!(flag: 'mass_messages', enabled: true)
  end

  scenario 'user sends mass message', :js do
    step 'when user logs' do
      login_as(user, scope: :user)
    end

    step 'user creates clients' do
      travel_to 7.days.ago do
        add_client(client_1)
      end

      travel_to 1.day.ago do
        add_client(client_2)
      end

      travel_to 1.hour.ago do
        add_client(client_3)
      end
    end

    step 'user sends message to client' do
      client_id = Client.find_by(phone_number: client_2.phone_number).id
      visit client_messages_path(client_id)
      fill_in "Send a text message", with: message.body

      perform_enqueued_jobs do
        click_on 'Send'
        expect(page).to have_css '.message--outbound div', text: message.body
      end

      visit clients_path
    end

    step 'when user navigates to mass message creation' do
      click_on 'Mass message'
      expect(page).to have_content 'New mass message'
    end

    step 'user sees clients list sorted by date of last contact' do
      within '.list' do
        expect(page.first('tr')).to have_content client_2.full_name
        expect(page.all('tr').last).to have_content client_1.full_name
      end
    end

    step 'user tries to submit invalid message' do
      click_on 'Send'
      expect(page).to have_content 'You need to add a message.'
    end

    step 'user sees character count' do
      expect(page.find('.new_mass_message .character-count')).to have_content(0)

      fill_in 'Your message', with: message_body

      expect(page.find('.new_mass_message .character-count')).to have_content(40)

      fill_in 'Your message', with: long_message_body

      expect(page.find('.new_mass_message .character-count')).to have_content(165)
      expect(page.find('.relative-container')).to have_css('.character-count.text--error')
    end

    step 'user can select all clients' do
      check 'Select all'

      expect(find('#select_all')['checked']).to eq true

      id_1 = Client.find_by(phone_number: client_1.phone_number).id
      id_2 = Client.find_by(phone_number: client_2.phone_number).id
      id_3 = Client.find_by(phone_number: client_3.phone_number).id

      expect(find("#mass_message_clients_#{id_1}")['checked']).to eq(true)
      expect(find("#mass_message_clients_#{id_2}")['checked']).to eq(true)
      expect(find("#mass_message_clients_#{id_3}")['checked']).to eq(true)

      find('tr', text: client_1.full_name).click
      expect(find('#select_all')['checked']).to eq(false)
    end

    step 'user can sort clients' do
      find('th', text: 'Name').click
      expect(page).to have_content(/#{client_1.full_name}.*#{client_2.full_name}.*#{client_3.full_name}/)
      find('th', text: 'Name').click
      expect(page).to have_content(/#{client_3.full_name}.*#{client_2.full_name}.*#{client_1.full_name}/)
    end

    step 'user can search for clients' do
      fill_in 'Search clients by name', with: 'a'
      expect(page).to have_content client_1.full_name
      expect(page).to_not have_content client_2.full_name
      expect(page).to_not have_content client_3.full_name

      click_on 'clear_search'
      expect(page).to have_content client_1.full_name
      expect(page).to have_content client_2.full_name
      expect(page).to have_content client_3.full_name
    end

    step 'then user sends message' do
      click_on 'Send'

      expect(page).to have_current_path(clients_path)
      expect(page).to have_content 'Your mass message has been sent.'
    end

    step 'then messages were sent to client 1 and 3' do
      expect(Message.where(body: long_message_body).count).to eq 2
      expect(Client.find_by(phone_number: client_2.phone_number).messages.last.body).to eq long_message_body
      expect(Client.find_by(phone_number: client_3.phone_number).messages.last.body).to eq long_message_body
    end
  end
end
