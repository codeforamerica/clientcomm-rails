require "rails_helper"
include ActiveJob::TestHelper

feature 'editing scheduled messages' do
  let(:message_body) {'You have an appointment tomorrow at 10am'}
  let(:userone) { create :user }
  let(:clientone) { create :client, user: userone }
  let(:future_date) { Time.now.tomorrow }
  let!(:scheduled_message) { create :message, client: clientone, user: userone, body: message_body, send_at: future_date }

  scenario 'user sends message to client', :js do
    step 'when user logs in' do
      login_as(userone, scope: :user)
    end

    step 'when user goes to messages page' do
      clientone_id = Client.find_by(phone_number: PhoneNumberParser.normalize(clientone.phone_number)).id
      visit client_messages_path(client_id: clientone_id)
      expect(page).to have_css '.notice', text: '1 message scheduled'
    end

    step 'when user clicks on scheduled message notice' do
      click_on '1 message scheduled'
      expect(page).to have_css '#scheduled-list-modal .modal-title', text: 'Manage scheduled messages'
      expect(page).to have_css '#scheduled-list', text: message_body
    end

    step 'when user clicks on edit message' do
      click_on 'Edit'
      expect(page).to have_css '#edit-message-modal .modal-title', text: 'Edit your message'
      expect(page).to have_css '#scheduled_message_body', text: message_body # expect body text field to contain message.body
      expect(page).to have_select('scheduled_message_send_at_1i', selected: future_date.year.to_s)
      expect(page).to have_select('scheduled_message_send_at_2i', selected: Date::MONTHNAMES[future_date.month])
      expect(page).to have_select('scheduled_message_send_at_3i', selected: future_date.day.to_s)
      expect(page).to have_select('scheduled_message_send_at_4i', selected: future_date.hour.to_s)
      expect(page).to have_select('scheduled_message_send_at_5i', selected: future_date.min.to_s)
      # expect time fields to be filled out with message.send_at
    end

    step 'when user edits a message' do
      # fill out body field with new message
      # change time field to new time
      # expect message.reload.send_at to eq new time
      # expect message.body to eq new body
    end

    # step 'then user sees the message displayed' do
    #   expect(page).to have_css '.message--outbound div', text: message_body
    #   expect(page).to_not have_css '.flash__message', text: 'Your message has been scheduled'

    #   # get the message object and find the dom_id
    #   clientone_id = Client.find_by(phone_number: PhoneNumberParser.normalize(clientone.phone_number)).id
    #   mymessage = Message.find_by(client_id: clientone_id, body: message_body)
    #   expect(page).to have_css '.message--outbound', id: dom_id(mymessage)
    # end

    # step 'when user visits the clients page' do
    #   visit clients_path
    # end

    # step 'then user sees clients sorted by last contact time' do
    #   savedfirstclient = Client.find_by(phone_number: PhoneNumberParser.normalize(clientone.phone_number))
    #   savedsecondclient = Client.find_by(phone_number: PhoneNumberParser.normalize(client_2.phone_number))
    #   expect(page).to have_css "tr##{dom_id(savedfirstclient)} td", text: 'less than a minute'
    #   expect(page).to have_css "tr##{dom_id(savedsecondclient)} td", text: '7 days'
    # end
  # end

  # scenario 'user schedules a message to client', :js do
    # step 'when user logs in' do
    #   myuser = create :user
    #   login_as(myuser, scope: :user)
    # end

    # step 'when user creates a clients' do
    #   travel_to 7.days.ago do
    #     add_client(clientone)
    #   end
    # end

    # step 'when user goes to messages page' do
    #   clientone_id = Client.find_by(phone_number: PhoneNumberParser.normalize(clientone.phone_number)).id
    #   visit client_messages_path(client_id: clientone_id)
    # end

    # step 'when user schedules a message' do
    #   click_on 'Send later'
    #   expect(page).to have_content('Send message later')
    #   fill_in 'Your message text', with: message_body

    #   future_date = Time.now + 7.days
    #   expect(page).to have_css '#message_send_at_1i'

    #   select future_date.year, from: 'message_send_at_1i'
    #   select Date::MONTHNAMES[future_date.month], from: 'message_send_at_2i'
    #   select future_date.day, from: 'message_send_at_3i'
    #   select "%02d" % future_date.hour, from: 'message_send_at_4i'
    #   select "%02d" % future_date.min, from: 'message_send_at_5i'

    #   perform_enqueued_jobs do
    #     click_on 'Schedule message'
    #   end

    #   expect(page).to_not have_content('Send message later')
    # end

    # step 'then user sees the pending message displayed' do
    #   expect(page).not_to have_css '.message--outbound div', text: message_body

    #   expect(page).to have_css '.flash__message', text: 'Your message has been scheduled'
    #   expect(page).to have_css '.notice', text: '1 message scheduled'
    # end

  end
end
