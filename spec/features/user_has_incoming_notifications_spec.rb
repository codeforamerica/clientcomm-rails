require 'rails_helper'

feature 'User receives a message from a client' do
  let(:phone_number) { 'something clever' }
  let(:department) { create :department, phone_number: phone_number }
  let(:clientone) { build :client, phone_number: '+12431551212' }
  let(:clienttwo) { build :client, phone_number: '+12432551212' }
  let(:myuser) { create :user, department: department }

  before do
    login_as(myuser, scope: :user)
    # create a new client
    add_client(clientone)
    add_client(clienttwo)

    visit clients_path
  end

  context 'while on the clients page' do
    it 'and sees a notification for a new message', :js do
      twilio_post_sms(twilio_new_message_params(
                        from_number: clientone.phone_number,
                        to_number: phone_number
      ))
      expect(page).to have_css '.flash p', text: "You have 1 unread message from #{clientone.full_name}"
    end

    it 'and sees a refreshed client list', :js do
      travel_to 5.days.ago do
        twilio_post_sms(twilio_new_message_params(
                          from_number: clientone.phone_number,
                          to_number: phone_number
        ))
      end

      travel_to 5.minutes.ago do
        twilio_post_sms(twilio_new_message_params(
                          from_number: clientone.phone_number,
                          to_number: phone_number
        ))
      end

      visit clients_path
      expect(page).to have_css '.unread td', text: '5 minutes'
      expect(page.body.index(clientone.full_name)).to be < page.body.index(clienttwo.full_name)

      twilio_post_sms(twilio_new_message_params(
                        from_number: clienttwo.phone_number,
                        to_number: phone_number
      ))

      expect(page).to have_css '.flash p', text: 'You have 3 unread messages'
      expect(page).to have_css '.unread td', text: 'just now'
      expect(page.body.index(clienttwo.full_name)).to be < page.body.index(clientone.full_name)
    end

    it 'sees a notification for only new messages from a client', :js do
      # post a message to the twilio endpoint from a user
      twilio_post_sms(twilio_new_message_params(
                        from_number: clientone.phone_number,
                        to_number: phone_number
      ))
      # there's a flash with the correct content
      flash_text = "You have 1 unread message from #{clientone.full_name}"
      expect(page).to have_css '.flash p', text: flash_text
      # get the saved client record
      clientone_record = Client.find_by(phone_number: clientone.phone_number)
      # click the flash to go to the messages page
      click_on flash_text
      expect(current_path).to eq reporting_relationship_path(myuser.reporting_relationships.find_by(client: clientone_record))
      # return to the clients page
      visit clients_path
      # post a second message
      twilio_post_sms(twilio_new_message_params(
                        from_number: clientone_record.phone_number,
                        to_number: phone_number
      ))
      # we should see the same flash message, because the first
      # message was marked read
      expect(page).to have_css '.flash p', text: flash_text
    end
  end
end
