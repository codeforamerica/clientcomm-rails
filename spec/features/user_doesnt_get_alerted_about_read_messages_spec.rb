require "rails_helper"

feature "User receives messages from a client" do
  let(:clientone) { build :client, phone_number: '+12431551212' }

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
    it "sees a notification for only new messages from a client", :js do
      # post a message to the twilio endpoint from a user
      twilio_post_sms(twilio_new_message_params(from_number: clientone.phone_number))
      # there's a flash with the correct content
      flash_text = "You have 1 unread message from #{clientone.full_name}"
      expect(page).to have_css '.flash p', text: flash_text
      # get the saved client record
      clientone_record = Client.where(phone_number: clientone.phone_number).first
      # click the flash to go to the messages page
      click_on flash_text
      expect(current_path).to eq client_messages_path(clientone_record.id)
      # return to the clients page
      visit clients_path
      # post a second message
      twilio_post_sms(twilio_new_message_params(from_number: clientone_record.phone_number))
      # we should see the same flash message, because the first
      # message was marked read
      expect(page).to have_css '.flash p', text: flash_text
    end
  end
end
