require 'rails_helper'

feature 'User receives a message from a client', :js do
  let(:phone_number) { 'anything I want' }
  let(:department) { create :department, phone_number: phone_number }
  let(:user1) { create :user, department: department }
  let(:client1) { create :client, user: user1 }

  before do
    login_as(user1, scope: :user)
  end

  context "while on the client's messages page" do
    it 'marks the message as read' do
      # go to the messages page
      rr = user1.reporting_relationships.find_by(client: client1)
      visit reporting_relationship_path(rr)
      # post a message to the twilio endpoint from the user
      twilio_post_sms(twilio_new_message_params(
                        from_number: client1.phone_number,
                        to_number: phone_number
      ))
      # there's a message with the correct contents
      expect(page).to have_css '.message--inbound div', text: twilio_message_text
      sleep 0.5
      wait_for_ajax # visiting the page calls $.ajax to mark all messages read

      # now load the message index
      visit clients_path
      # the client isn't marked as having unread messages
      expect(page).to have_css '.read td', text: client1.full_name
    end

    context 'a message is sent to an external user' do
      let(:user2) { create :user }

      before do
        user2.clients << client1
        login_as(user2, scope: :user)
      end

      it 'does not stream messages to the incorrect user' do
        rr = user1.reporting_relationships.find_by(client: client1)
        visit reporting_relationship_path(rr)
        # post a message to the twilio endpoint from the user
        twilio_post_sms(twilio_new_message_params(
                          from_number: client1.phone_number,
                          to_number: phone_number
        ))
        # there's a message with the correct contents
        expect(page).not_to have_css '.message--inbound div', text: twilio_message_text
        wait_for_ajax # visiting the page calls $.ajax to mark all messages read
      end
    end
  end
end
