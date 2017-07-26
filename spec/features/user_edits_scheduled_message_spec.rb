require "rails_helper"
feature 'editing scheduled messages', active_job: true do
  let(:message_body) {'You have an appointment tomorrow at 10am'}
  let(:new_message_body) {'Your appointment tomorrow has been cancelled'}
  let(:userone) { create :user }
  let(:clientone) { create :client, user: userone }
  let(:future_date) { Time.now.tomorrow }
  let(:new_future_date) { future_date.tomorrow }
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
      expect(page).to have_select('scheduled_message_send_at_1i', selected: future_date.strftime("%Y"))
      expect(page).to have_select('scheduled_message_send_at_2i', selected: Date::MONTHNAMES[future_date.month])
      expect(page).to have_select('scheduled_message_send_at_3i', selected: future_date.strftime("%-d"))
      expect(page).to have_select('scheduled_message_send_at_4i', selected: future_date.strftime("%H"))
      expect(page).to have_select('scheduled_message_send_at_5i', selected: future_date.strftime("%M"))
      # expect time fields to be filled out with message.send_at
    end

    step 'when user edits a message' do

      fill_in 'scheduled_message_body', with: new_message_body

      select new_future_date.year, from: 'scheduled_message_send_at_1i'
      select Date::MONTHNAMES[new_future_date.month], from: 'scheduled_message_send_at_2i'
      select new_future_date.day, from: 'scheduled_message_send_at_3i'
      select "%02d" % new_future_date.hour, from: 'scheduled_message_send_at_4i'
      select "%02d" % new_future_date.min, from: 'scheduled_message_send_at_5i'

      perform_enqueued_jobs do
        click_on 'Update'
        expect(page).to have_current_path(client_messages_path(scheduled_message.client))
      end
    end

    step 'then when user edits the message again' do
      click_on '1 message scheduled'
      expect(page).to have_css '#scheduled-list-modal .modal-title', text: 'Manage scheduled messages'
      expect(page).to have_css '#scheduled-list', text: new_message_body

      click_on 'Edit'
      expect(page).to have_content 'Edit your message'

      expect(page).to have_css '#scheduled_message_body', text: new_message_body # expect body text field to contain message.body
      expect(page).to have_select('scheduled_message_send_at_1i', selected: new_future_date.strftime("%Y"))
      expect(page).to have_select('scheduled_message_send_at_2i', selected: Date::MONTHNAMES[new_future_date.month])
      expect(page).to have_select('scheduled_message_send_at_3i', selected: new_future_date.strftime("%-d"))
      expect(page).to have_select('scheduled_message_send_at_4i', selected: new_future_date.strftime("%H"))
      expect(page).to have_select('scheduled_message_send_at_5i', selected: new_future_date.strftime("%M"))
    end

    step 'when the user clicks the button to dismiss the modal' do
      click_on '×'
      expect(page).to have_current_path(client_messages_path(clientone))
    end
  end
end
