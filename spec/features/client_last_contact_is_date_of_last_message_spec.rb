require "rails_helper"

feature "User schedules a message for later and submits it", :js, active_job: true do

  let(:message_body) {'You have an appointment tomorrow at 10am.You have an appointment tomorrow at 10am.You have an appointment tomorrow at 10am.'}
  let(:future_date) { Time.now.change(min: 0, day: 3) + 1.month }
  let(:user) { create :user }
  let(:client) { build :client }

  scenario "then returns to clients list" do
    travel_to 7.days.ago do
      login_as(user, :scope => :user)
      add_client(client)
    end

    step 'when user goes to messages page' do
      page.find('td', text: client.full_name).click
    end

    step 'when user clicks on send later button' do
      click_button 'Send later'
    end

    step 'when user creates a scheduled message' do
      # if we don't interact with the datepicker, it persists and
      # covers other ui elements
      fill_in 'Date', with: ""
      find('.ui-datepicker-next').click
      click_on future_date.strftime("%-d")

      select future_date.strftime("%-l:%M%P"), from: 'Time'
      fill_in 'scheduled_message_body', with: message_body

      click_on 'Schedule message'
      expect(page).to have_content client.full_name
      expect(page).to have_content '1 message scheduled'
    end

    step 'return to client messages path' do
      visit clients_path

      client_row = page.find('tr', text: client.full_name)

      expect(client_row).to have_content('7 days')
    end

  end
end
