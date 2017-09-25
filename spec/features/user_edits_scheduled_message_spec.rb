require "rails_helper"

feature 'creating and editing scheduled messages', active_job: true do
  let(:message_body) {'You have an appointment tomorrow at 10am.You have an appointment tomorrow at 10am.You have an appointment tomorrow at 10am.'}
  let(:truncated_message_body) {'You have an appointment tomorrow at 10am.You have an appointment tomorrow at ...'}
  let(:new_message_body) {'Your appointment tomorrow has been cancelled'}
  let(:userone) { create :user }
  let(:clientone) { create :client, user: userone }
  let(:future_date) { Time.now.change(min: 0, day: 3) + 1.month }
  let(:new_future_date) { future_date.change(min: 0, day: 4) }

  scenario 'user schedules and edits message for client', :js do
    step 'when user logs in' do
      login_as(userone, scope: :user)
    end

    step 'when user goes to messages page' do
      clientone_id = Client.find_by(phone_number: PhoneNumberParser.normalize(clientone.phone_number)).id
      visit client_messages_path(client_id: clientone_id)
      expect(page).not_to have_content '1 message scheduled'
    end

    step 'when user clicks on send later button' do
      click_button 'Send later'
      expect(page).to have_content 'Send message later'
      expect(page).not_to have_content 'Delete message'
    end

    step 'when user creates a scheduled message' do
      # if we don't interact with the datepicker, it persists and
      # covers other ui elements
      fill_in 'Date', with: ""
      find('.ui-datepicker-next').click
      click_on future_date.strftime("%-d")

      select future_date.strftime("%-l:%M%P"), from: 'Time'
      fill_in 'scheduled_message_body', with: message_body

      perform_enqueued_jobs do
        click_on 'Schedule message'
        expect(page).to have_current_path(client_messages_path(clientone))
        expect(page).to have_content '1 message scheduled'
      end
    end

    step 'when user clicks on scheduled message notice' do
      click_on '1 message scheduled'
      expect(page).to have_current_path(client_scheduled_messages_index_path(clientone))
      expect(page).to have_content 'Manage scheduled messages'
      expect(page).to have_content truncated_message_body
    end

    step 'when user clicks on edit message' do
      messageone_id = Message.last().id
      click_on 'Edit'
      expect(page).to have_current_path(edit_message_path(messageone_id))
      expect(page).to have_content 'Edit your message'
      expect(page).to have_css('.send-later-input', text: message_body, visible: :all)
      expect(page).to have_field('Date', with: future_date.strftime("%m/%d/%Y"))
      expect(page).to have_select('Time', selected: future_date.strftime("%-l:%M%P"))
      expect(page).to have_content 'Delete message'
    end

    step 'when user edits a message' do
      # if we don't interact with the datepicker, it persists and
      # covers other ui elements
      fill_in 'Date', with: ""
      click_on new_future_date.strftime("%-d")

      select new_future_date.strftime("%-l:%M%P"), from: 'Time'

      expect(page.find('form.edit_message .character-count')).to have_content(123)

      fill_in 'scheduled_message_body', with: new_message_body

      expect(page.find('form.edit_message .character-count')).to have_content(44)

      perform_enqueued_jobs do
        click_on 'Update'
        expect(page).to have_current_path(client_messages_path(clientone))
      end
    end

    step 'then when user edits the message again' do
      messageone_id = Message.last().id
      click_on '1 message scheduled'
      expect(page).to have_current_path(client_scheduled_messages_index_path(clientone))
      expect(page).to have_content 'Manage scheduled messages'
      expect(page).to have_content new_message_body

      click_on 'Edit'
      expect(page).to have_current_path(edit_message_path(messageone_id))
      expect(page).to have_content 'Edit your message'
      # TODO flakes because modal animation doesn't finish
      expect(page).to have_css('.send-later-input', text: new_message_body, visible: :all)
      expect(page).to have_field('Date', with: new_future_date.strftime("%m/%d/%Y"))
      expect(page).to have_select('Time', selected: new_future_date.strftime("%-l:%M%P"))
    end

    step 'when the user clicks the button to dismiss the modal' do
      click_on '×'
      expect(page).to have_no_css '#scheduled-list-modal'
    end

    step 'when user clicks on scheduled message notice' do
      click_on '1 message scheduled'
      expect(page).to have_current_path(client_scheduled_messages_index_path(clientone))
      expect(page).to have_content 'Manage scheduled messages'
      expect(page).to have_content new_message_body
    end

    step 'when the user clicks the button to dismiss the modal' do
      click_on '×'
      expect(page).to have_no_css '#scheduled-list-modal'
    end

    step 'then when user edits the message again' do
      messageone_id = Message.last().id
      click_on '1 message scheduled'
      expect(page).to have_current_path(client_scheduled_messages_index_path(clientone))
      expect(page).to have_content 'Manage scheduled messages'
      expect(page).to have_content new_message_body

      click_on 'Edit'
      expect(page).to have_current_path(edit_message_path(messageone_id))
      expect(page).to have_content 'Edit your message'
      # TODO flakes because modal animation doesn't finish
      expect(page).to have_css('.send-later-input', text: new_message_body, visible: :all)
      expect(page).to have_field('Date', with: new_future_date.strftime("%m/%d/%Y"))
      expect(page).to have_select('Time', selected: new_future_date.strftime("%-l:%M%P"))
    end

    step 'when the user clicks the delete button' do
      click_on 'Delete message'

      expect(page).to have_current_path(client_messages_path(clientone))
      expect(page).not_to have_content('1 message scheduled')
    end
  end
end
