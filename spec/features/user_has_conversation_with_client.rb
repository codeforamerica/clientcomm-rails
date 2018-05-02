require 'rails_helper'
feature 'sending messages', active_job: true do
  let(:message_body) { 'You have an appointment tomorrow at 10am' }
  let(:long_message_body) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent aliquam consequat mauris id sollicitudin. Aenean nisi nibh, ullamcorper non justo ac, egestas amet.' }
  let(:too_long_message_body) { 'abcd' * 401 }
  let(:client_1) { create :client, users: [myuser] }
  let(:client_2) { create :client, users: [myuser] }
  let(:myuser) { create :user }

  before do
    login_as(myuser, scope: :user)
  end

  scenario 'user sends message to client', :js, active_job: true do
    step 'when user goes to messages page' do
      rr = myuser.reporting_relationships.find_by(client: client_1)
      visit reporting_relationship_path(rr)
    end

    step 'when user enters a message that is too long' do
      fill_in 'Send a text message', with: too_long_message_body

      expect(page).to have_content('This message is more than 1600 characters and is too long to send.')
      expect(page).to have_button('Send', disabled: true)
      expect(page).to have_button('Send later', disabled: true)
    end

    step 'when user sends a message' do
      fill_in 'Send a text message', with: long_message_body

      expect(page).to have_content('Because of its length, this message may be sent as 2 texts.')
      expect(page.find('.sendbar')).to have_css('.character-count.text--error')
      expect(page).to have_button('Send', disabled: false)
      expect(page).to have_button('Send later', disabled: false)

      fill_in 'Send a text message', with: message_body

      perform_enqueued_jobs do
        click_on 'send_message'
        expect(page).to_not have_content('Because of its length, this message may be sent as 2 texts.')
        expect(page).to have_css '.message--outbound div', text: message_body
      end
    end

    step 'when the client responds' do
      # post a message to the twilio endpoint from the user
      perform_enqueued_jobs do
        twilio_post_sms(twilio_new_message_params(
                          from_number: client_1.phone_number,
                          to_number: myuser.department.phone_number
        ))
      end

      # there's a message with the correct contents
      expect(page).to have_css '.message--inbound div', text: twilio_message_text
      wait_for_ajax
      # there's no flash notification
      expect(page).to have_no_css '.flash'
    end
  end

  scenario 'user schedules a message to client', :js do
    step 'when user logs in' do
      login_as(myuser, scope: :user)
    end

    step 'when user creates a clients' do
      travel_to 7.days.ago do
        add_client(client_1)
      end
    end

    step 'when user goes to messages page' do
      client = Client.find_by(phone_number: client_1.phone_number).id
      rr = myuser.reporting_relationships.find_by(client: client)
      visit reporting_relationship_path(rr)
    end

    step 'when user schedules a message' do
      incomplete_message = 'incomplete message'
      fill_in 'Send a text message', with: incomplete_message
      click_button 'Send later'
      expect(page).to have_content('Send message later')
      expect(find_field('Your message text').value).to eq incomplete_message
    end

    step 'when user enters a message that is too long' do
      fill_in 'Send a text message', with: too_long_message_body

      expect(page).to have_content('This message is more than 1600 characters and is too long to send.')
      expect(page).to have_button('Schedule message', disabled: true)
    end

    step 'enters a valid message' do
      fill_in 'Your message text', with: long_message_body

      expect(page.find('#scheduled_new_message  .character-count')).to have_content('Because of its length, this message may be sent as 2 texts.')
      expect(page.find('#scheduled_new_message')).to have_css('.character-count.text--error')

      fill_in 'Your message text', with: message_body

      future_date = (Time.zone.today + 1.month).beginning_of_month

      # if we don't interact with the datepicker, it persists and
      # covers other ui elements
      fill_in 'Date', with: ''
      find('.ui-datepicker-next').click
      click_on future_date.strftime('%-d')
      select future_date.change(min: 0).strftime('%-l:%M%P'), from: 'Time'

      perform_enqueued_jobs do
        click_on 'Schedule message'
      end

      expect(page).to_not have_content('Schedule message')
    end

    step 'then user sees the pending message displayed' do
      expect(page).not_to have_css '.message--outbound div', text: message_body

      expect(page).to have_css '.flash__message', text: 'Your message has been scheduled'
      expect(page).to have_content '1 message scheduled'
    end
  end
end
