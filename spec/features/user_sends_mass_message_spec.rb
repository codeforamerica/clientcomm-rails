require "rails_helper"

feature 'sending mass messages', active_job: true do
  let(:message_body) {'You have an appointment tomorrow at 10am'}
  let(:user) { create :user }

  scenario 'user sends mass message', :js do
    step 'when user logs in' do
      login_as(user, scope: :user)
      visit clients_path
    end

    step 'when user creates two clients' do
      create :client, user: user
      create :client, user: user
    end

    step 'when user starts a mass message' do
      click_on 'Mass message'
    end

    step 'then user sees the client selection page' do
      expect(page).to have_content 'New mass message'
    end
  end
end
