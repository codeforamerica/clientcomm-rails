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
      myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(clientone.phone_number)).id
      visit client_messages_path(client_id: myclient_id)
      # post a message to the twilio endpoint from the user
      twilio_post_sms(twilio_new_message_params(clientone.phone_number))
      # there's a message with the correct contents
      expect(page).to have_css '.message--inbound p', text: twilio_message_text
      # there's only one message in the database, and it's marked read
      all_messages = Message.all
      expect(all_messages.length).to eq 1
      expect(all_messages.first.read).to eq true
    end
  end
end
