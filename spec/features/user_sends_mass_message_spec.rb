require "rails_helper"

feature 'sending mass messages', active_job: true do
  let(:message_body) {'You have an appointment tomorrow at 10am'}
  let(:user) { create :user }
  let!(:client_1) { create :client, user: user }
  let!(:client_2) { create :client, user: user }
  let!(:client_3) { create :client, user: user }

  scenario 'user sends mass message', :js do
    step 'when user logs in' do
      login_as(user, scope: :user)
      visit clients_path
    end

    step 'when user navigates to mass message creation' do
      click_on 'Mass message'
      expect(page).to have_content 'New mass message'
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
