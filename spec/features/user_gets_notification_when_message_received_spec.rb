require "rails_helper"

feature "User receives a message from a client" do
  let(:clientone) { build :client, phone_number: '+12431551212' }
  let(:clienttwo) { build :client, phone_number: '+12432551212' }

  before do
    # log in with a fake user
    myuser = create :user
    login_as(myuser, scope: :user)
    # create a new client
    visit new_client_path
    add_client(clientone)
    visit new_client_path
    add_client(clienttwo)
    # end up on the clients page
    expect(current_path).to eq clients_path
  end

  context "while on the clients page" do
    it "and sees a notification for a new message", :js do
      # post a message to the twilio endpoint from the user
      twilio_post_sms(twilio_new_message_params(from_number: clientone.phone_number))
      # there's a flash with the correct contents
      expect(page).to have_css '.flash p', text: "You have 1 unread message from #{clientone.full_name}"
    end

    it "and sees a refreshed client list", :js do
      # post a message to the twilio endpoint from the first user 5 minutes ago
      travel_to 5.minutes.ago do
        twilio_post_sms(twilio_new_message_params(from_number: clientone.phone_number))
      end
      # validate the order of the clients in the list
      visit clients_path
      expect(page).to have_css '.unread td', text: clientone.full_name
      expect(page.body.index(clientone.full_name)).to be < page.body.index(clienttwo.full_name)
      # send a message from client two and check the new order
      twilio_post_sms(twilio_new_message_params(from_number: clienttwo.phone_number))
      expect(page).to have_css '.flash p', text: "You have 2 unread messages"
      expect(page).to have_css '.unread td', text: clienttwo.full_name
      expect(page.body.index(clienttwo.full_name)).to be < page.body.index(clientone.full_name)
    end
  end

  context "while on the clients' messages page" do
    it "doesn't see a notification for a new message", :js do
      # go to messages page
      myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(clientone.phone_number)).id
      visit client_messages_path(client_id: myclient_id)  
      # post a message to the twilio endpoint from the user
      twilio_post_sms(twilio_new_message_params(from_number: clientone.phone_number))
      # there's a message with the correct contents
      expect(page).to have_css '.message--inbound div', text: twilio_message_text
      # there's no flash notification
      expect(page).to have_no_css '.flash'
    end
  end
end
