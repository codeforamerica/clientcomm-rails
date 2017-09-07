require "rails_helper"

feature 'sending mass messages', active_job: true do
  let(:message_body) {'You have an appointment tomorrow at 10am'}
  let(:user) { create :user }
  let!(:client_1) { build :client }
  let!(:client_2) { build :client }
  let!(:client_3) { build :client }
  let!(:message) { build :message }

  scenario 'user sends mass message', :js do
    step 'when user logs' do
      login_as(user, scope: :user)
    end

    step 'user creates clients' do

      travel_to 7.days.ago do
        visit new_client_path
        add_client(client_1)
      end

      travel_to 1.day.ago do
        visit new_client_path
        add_client(client_2)
      end

      travel_to 1.hour.ago do
        visit new_client_path
        add_client(client_3)
      end
    end

    step 'user sends message to client' do
      client_id = Client.find_by(phone_number: PhoneNumberParser.normalize(client_2.phone_number)).id
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

    step 'then user fills in message text and recipients' do
      fill_in 'Your message', with: message_body

      check client_1.full_name
      check client_3.full_name
      click_on 'Send'

      expect(page).to have_current_path(clients_path)
      expect(page).to have_content 'Your mass message has been sent.'
    end
  end
end
