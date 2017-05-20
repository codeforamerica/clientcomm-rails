require "rails_helper"

feature "User enters a message and submits it" do
  scenario "and sees the message on the client's messages page" do
    # log in with a fake user
    myuser = create :user
    login_as(myuser, :scope => :user)
    # create a new client
    visit new_client_path
    myclient = build :client
    add_client(myclient)
    # go to messages page
    myclient_id = Client.find_by(phone_number: myclient.phone_number).id
    visit client_messages_path(client_id: myclient_id)
    # enter a message in the form
    message_body = "You have an appointment tomorrow at 10am"
    fill_in "Send a text message", with: message_body
    click_on "Send"
    # look for the message on the page
    expect(page).to have_css '.card p', text: message_body
  end
end
