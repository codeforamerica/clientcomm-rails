require 'rails_helper'

feature 'sending messages', active_job: true do
  let(:message_body) { 'You have an appointment tomorrow at 10am' }
  let(:another_message_body) { 'Actually your appointment is rescheduled to 10:30am' }
  let(:long_message_body) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent aliquam consequat mauris id sollicitudin. Aenean nisi nibh, ullamcorper non justo ac, egestas amet.' }
  let(:too_long_message_body) { 'abcd' * 401 }
  let(:old_phone_number) { '+14155551111' }
  let(:new_phone_number) { '+14155551112' }
  let(:new_phone_number_display) { '(415) 555-1112' }
  let(:client_one) { create :client, users: [user_one], phone_number: old_phone_number }
  let(:client_two) { create :client, users: [user_one] }
  let(:user_one) { create :user }
  let(:rr) { user_one.reporting_relationships.find_by(client: client_one) }

  before do
    login_as(user_one, scope: :user)
  end

  scenario 'user sends message to client', :js, active_job: true do
    step 'when user goes to conversation page' do
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
      expect(page.find('#sendbar-container')).to have_css('.character-count.text--error')
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
      perform_enqueued_jobs do
        twilio_post_sms(twilio_new_message_params(
                          from_number: client_one.phone_number,
                          to_number: user_one.department.phone_number
        ))
      end

      expect(page).to have_css '.message--inbound div', text: twilio_message_text
      wait_for_ajax
      expect(page).to have_no_css '.flash'
    end

    step 'when the user is not in the treatment group' do
      expect(page).to_not have_css('like-options')
    end

    step 'when the user is added to the treatment group' do
      user_one.update(treatment_group: 'ebp-liking-messages')
      visit reporting_relationship_path(rr)

      expect(page).to have_css('like-options')
    end

    step 'the user clicks a positive reinforcement message button' do
      option = find('like-options like-option:first-child')
      option_text = option.text

      option.click

      expect(page.find('textarea#message_body').value).to eq(option_text)
      expect(page).to have_css('like-options', visible: :hidden)

      perform_enqueued_jobs do
        click_on 'send_message'
        expect(page).to have_css '.message--outbound div', text: option_text
      end

      wait_for_ajax

      expect_most_recent_analytics_event(
        'message_send' => {
          'positive_template' => true,
          'positive_template_type' => option_text
        }
      )
    end

    step 'postive reinforcements do not show up if the last message was outbound' do
      visit reporting_relationship_path(rr)
      expect(page).to have_css('like-options', visible: :hidden)
    end

    step 'positive reinforcements are not visible if the last message is a marker' do
      click_on 'Manage client'
      expect(page).to have_current_path(edit_client_path(client_one))
      fill_in 'Phone number', with: new_phone_number
      click_on 'Save changes'
      expect(page).to have_current_path(reporting_relationship_path(rr))
      expect(page).to have_css '.message--event', text:
        I18n.t(
          'messages.phone_number_edited_by_you',
          new_phone_number: new_phone_number_display
        )
      expect(page).to have_css('like-options', visible: :hidden)
    end

    step 'positive reinforcement messages reappear when a message comes in' do
      client_one.reload
      perform_enqueued_jobs do
        twilio_post_sms(twilio_new_message_params(
                          from_number: client_one.phone_number,
                          to_number: user_one.department.phone_number,
                          msg_txt: 'This message should trigger like options.'
        ))
      end

      expect(page).to have_css('like-options')
    end

    step 'user clicks positive reinforcement but deletes whole body' do
      find('like-options like-option:first-child').click

      fill_in 'Send a text message', with: ''
      fill_in 'Send a text message', with: another_message_body

      perform_enqueued_jobs do
        click_on 'send_message'
        expect(page).to have_css '.message--outbound div', text: another_message_body
      end

      wait_for_ajax

      expect_most_recent_analytics_event(
        'message_send' => {
          'positive_template' => false,
          'positive_template_type' => ''
        }
      )
    end
  end

  scenario 'user schedules a message to client', :js do
    step 'when user schedules a message' do
      visit reporting_relationship_path(rr)
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
