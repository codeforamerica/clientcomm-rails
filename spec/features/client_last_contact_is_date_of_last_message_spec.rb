require "rails_helper"

feature "User enters a message and submits it" do
  scenario "then sees the clients sorted by most recent contact" do
    myuser = nil
    myfirstclient = nil
    mysecondclient = nil
    # create a user and client a week ago
    travel_to 7.days.ago do
        # log in with a fake user
        myuser = create :user
        login_as(myuser, :scope => :user)
        # create a new client
        visit new_client_path
        myfirstclient = build :client
        add_client(myfirstclient)
        mysecondclient = build :client
        add_client(mysecondclient)
    end
    # go to messages page
    myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(myfirstclient.phone_number)).id
    visit client_messages_path(client_id: myclient_id)
    # enter a message in the form
    message_body = "You have an appointment tomorrow at 10am"
    fill_in "Send a text message", with: message_body
    click_on "send_message"
    # go to the client list and check the last contact times
    visit clients_path
    savedfirstclient = Client.find_by(phone_number: PhoneNumberParser.normalize(myfirstclient.phone_number))
    savedsecondclient = Client.find_by(phone_number: PhoneNumberParser.normalize(mysecondclient.phone_number))
    expect(page).to have_css "tr##{dom_id(savedfirstclient)} td", text: 'less than a minute', wait: 10
    expect(page).to have_css "tr##{dom_id(savedsecondclient)} td", text: '7 days'
  end
end

feature "User schedules a message for later and submits it", :js, active_job: true do

  let(:message_body) {'You have an appointment tomorrow at 10am.You have an appointment tomorrow at 10am.You have an appointment tomorrow at 10am.'}
  let(:future_date) { Time.now.change(min: 0, day: 3) + 1.month }
  let(:user) { create :user }
  let(:client) { build :client }

  scenario "then returns to clients list" do
    travel_to 7.days.ago do
      # log in with a fake user
      login_as(user, :scope => :user)
      # create a new client
      visit new_client_path
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

      perform_enqueued_jobs do
        click_on 'Schedule message'
        expect(page).to have_content client.full_name
        expect(page).to have_content '1 message scheduled'
      end
    end

    step 'return to client messages path' do
      visit clients_path

      client_row = page.find('tr', text: client.full_name)

      expect(client_row).to have_content('7 days')
    end

  end
end
