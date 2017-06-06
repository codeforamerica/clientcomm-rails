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
    expect(page).to have_css "tr##{dom_id(savedfirstclient)} td", text: 'less than a minute'
    expect(page).to have_css "tr##{dom_id(savedsecondclient)} td", text: '7 days'
  end
end
