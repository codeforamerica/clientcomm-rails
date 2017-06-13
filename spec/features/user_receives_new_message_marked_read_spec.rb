require "rails_helper"

feature "User receives a message from a client" do
  let(:userone) { create :user }
  let(:clientone) { create :client, user: userone }

  before do
    login_as(userone, scope: :user)
  end

  context "while on the client's messages page" do
    it "marks the message as read", :js do
      # go to the messages page
      clientone_phone = PhoneNumberParser.normalize(clientone.phone_number)
      clientone_id = Client.find_by(phone_number: clientone_phone).id
      visit client_messages_path(client_id: clientone_id)
      # post a message to the twilio endpoint from the user
      twilio_post_sms(twilio_new_message_params(clientone.phone_number))
      # there's a message with the correct contents
      expect(page).to have_css '.message--inbound p', text: twilio_message_text
      # send a message back
      message_body = "Hello from your case manager"
      fill_in "Send a text message", with: message_body
      # NOTE: hitting the enter key in the body field because
      # the submit button is hidden
      find('#message_body').native.send_keys :enter
      # find the message on the page
      expect(page).to have_css '.message--outbound p', text: message_body
      # now load the message index
      visit clients_path
      # the client isn't marked as having unread messages
      expect(page).to have_css '.read td', text: clientone.full_name
    end
  end
end
