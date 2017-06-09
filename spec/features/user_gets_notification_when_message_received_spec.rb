require "rails_helper"

feature "User receives a message from a client" do
  let(:myclient) { build :client, phone_number: twilio_new_message_params()['From'] }

  before do
    # log in with a fake user
    myuser = create :user
    login_as(myuser, scope: :user)
    # create a new client
    visit new_client_path
    add_client(myclient)
    # end up on the clients page
    expect(current_path).to eq clients_path
  end

  context "while on the clients page" do
    it "sees a notification for a new message", :js do
      # post a message to the twilio endpoint from the user
      twilio_post_sms()
      # there's a flash with the correct contents
      expect(page).to have_css '.flash p', text: "You have 1 new message from #{myclient.full_name}"
    end
  end

  context "while on the clients' messages page" do
    it "doesn't see a notification for a new message", :js do
      # go to messages page
      myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(myclient.phone_number)).id
      visit client_messages_path(client_id: myclient_id)  
      # post a message to the twilio endpoint from the user
      twilio_post_sms()
      # there's a message with the correct contents
      expect(page).to have_css '.message--inbound p', text: twilio_message_text
      # there's no flash notification
      expect(page).to have_no_css '.flash'
    end
  end
end
