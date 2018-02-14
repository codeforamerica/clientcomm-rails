require 'rails_helper'
feature 'sending messages', active_job: true do
  let(:message_body) { 'You have an appointment tomorrow at 10am' }
  let(:long_message_body) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent aliquam consequat mauris id sollicitudin. Aenean nisi nibh, ullamcorper non justo ac, egestas amet.' }
  let(:client_1) { build :client }
  let(:client_2) { build :client }
  let(:myuser) { create :user }

  scenario 'user sends message to client', :js do
    step 'when user logs in' do
      login_as(myuser, scope: :user)
    end

    step 'when user creates two clients' do
      travel_to 7.days.ago do
        add_client(client_1)
        add_client(client_2)
      end
    end

    step 'when user goes to messages page' do
      client = Client.find_by(phone_number: client_1.phone_number).id
      rr = myuser.reporting_relationships.find_by(client: client)
      visit reporting_relationship_path(rr)
    end

    step 'when user sends a message' do
      expect(page.find('.sendbar .character-count')).to have_content(/^0$/)

      fill_in 'Send a text message', with: message_body

      expect(page.find('.sendbar .character-count')).to have_content(/^40$/)

      fill_in 'Send a text message', with: long_message_body

      expect(page.find('.sendbar .character-count')).to have_content('This message may be sent as 2 texts.')
      expect(page.find('.sendbar')).to have_css('.character-count.text--error')

      fill_in 'Send a text message', with: message_body

      perform_enqueued_jobs do
        click_on 'send_message'
        expect(page.find('.sendbar .character-count')).to have_content(/^0$/)
        expect(page).to have_css '.message--outbound div', text: message_body
      end
    end

    step 'when user visits the clients page' do
      visit clients_path
    end

    step 'then user sees clients sorted by last contact time' do
      savedfirstclient = Client.find_by(phone_number: client_1.phone_number)
      savedsecondclient = Client.find_by(phone_number: client_2.phone_number)
      expect(page).to have_css "tr##{dom_id(savedfirstclient)} td", text: 'just now'
      expect(page).to have_css "tr##{dom_id(savedsecondclient)} td", text: '--'
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

      expect(page.find('#scheduled_new_message .character-count')).to have_content(18)

      fill_in 'Your message text', with: message_body

      expect(page.find('#scheduled_new_message  .character-count')).to have_content(40)

      fill_in 'Your message text', with: long_message_body

      expect(page.find('#scheduled_new_message  .character-count')).to have_content('This message may be sent as 2 texts.')
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
