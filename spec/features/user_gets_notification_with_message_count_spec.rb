require 'rails_helper'

feature 'User receives messages from clients' do
  let(:phone_number) { 'a phone number' }
  let(:department) { create :department, phone_number: phone_number }
  let(:clientone) { build :client, phone_number: '+12431551212' }
  let(:clienttwo) { build :client, phone_number: '+12432551212' }

  before do
    myuser = create :user, department: department
    login_as(myuser, scope: :user)
    add_client(clientone)

    visit clients_path
  end

  context 'while on the clients page' do
    it 'sees a notification for new messages from one client', :js do
      # post messages to the twilio endpoint from a user
      twilio_post_sms(twilio_new_message_params(
        from_number: clientone.phone_number,
        to_number: phone_number
      ))
      twilio_post_sms(twilio_new_message_params(
        from_number: clientone.phone_number,
        to_number: phone_number
      ))
      twilio_post_sms(twilio_new_message_params(
        from_number: clientone.phone_number,
        to_number: phone_number
      ))
      # there's a flash with the correct contents
      expect(page).to have_css '.flash p', text: "You have 3 unread messages from #{clientone.full_name}"
    end
  end
end
