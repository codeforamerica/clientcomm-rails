require "rails_helper"

feature "User receives messages from clients" do
  let(:clientone) { build :client, phone_number: '+12431551212' }
  let(:clienttwo) { build :client, phone_number: '+12432551212' }

  before do
    # log in with a fake user
    myuser = create :user
    login_as(myuser, scope: :user)
    # create a new client
    visit new_client_path
    add_client(clientone)
    # end up on the clients page
    expect(current_path).to eq clients_path
  end

  context "while on the clients page" do
    it "sees a notification for new messages from one client", :js do
      # post messages to the twilio endpoint from a user
      twilio_post_sms(twilio_new_message_params(clientone.phone_number))
      twilio_post_sms(twilio_new_message_params(clientone.phone_number))
      twilio_post_sms(twilio_new_message_params(clientone.phone_number))
      # there's a flash with the correct contents
      expect(page).to have_css '.flash p', text: "You have 3 unread messages from #{clientone.full_name}"
    end

    it "sees a notification for new messages from two clients", :js do
      # post messages to the twilio endpoint from both users
      # create a second new client
      visit new_client_path
      add_client(clienttwo)
      # end up on the clients page
      expect(current_path).to eq clients_path
      twilio_post_sms(twilio_new_message_params(clientone.phone_number))
      twilio_post_sms(twilio_new_message_params(clienttwo.phone_number))
      twilio_post_sms(twilio_new_message_params(clienttwo.phone_number))
      twilio_post_sms(twilio_new_message_params(clientone.phone_number))
      twilio_post_sms(twilio_new_message_params(clienttwo.phone_number))
      # there's a flash with the correct contents
      expect(page).to have_css '.flash p', text: "You have 5 unread messages"
    end
  end
end
