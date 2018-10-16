require 'rails_helper'

feature 'sending mass messages', active_job: true do
  let(:message_body) { 'You have an appointment tomorrow at 10am' }
  let(:long_message_body) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent aliquam consequat mauris id sollicitudin. Aenean nisi nibh, ullamcorper non justo ac, egestas amet.' }
  let(:too_long_message_body) { 'abcd' * 401 }
  let(:scheduled_message_body) { 'This is the text of a scheduled message' }
  let(:user) { create :user }
  let!(:client_1) { build :client, first_name: 'a', last_name: 'a' }
  let!(:client_2) { build :client, first_name: 'b', last_name: 'b' }
  let!(:client_3) { build :client, first_name: 'c', last_name: 'c' }
  let!(:message) { build :text_message }

  before do
    FeatureFlag.create!(flag: 'mass_messages', enabled: true)
  end

  scenario 'user sends mass message', :js do
    step 'when user logs in' do
      login_as(user, scope: :user)
    end

    step 'user has created clients' do
      travel_to 7.days.ago do
        add_client(client_1)
      end

      travel_to 1.day.ago do
        add_client(client_2)
      end

      travel_to 1.hour.ago do
        add_client(client_3)
      end
    end

    step 'user sends message to client' do
      client = Client.find_by(phone_number: client_2.phone_number)
      rr = user.reporting_relationships.find_by(client: client)
      visit reporting_relationship_path(rr)
      fill_in 'Send a text message', with: message.body

      perform_enqueued_jobs do
        click_on 'Send'
        expect(page).to have_css '.message--outbound div', text: message.body
      end

      visit clients_path
    end

    step 'when user navigates to mass message creation' do
      click_on 'Mass message'
      expect(page).to have_content 'New mass message'
    end

    step 'user sees clients list sorted by date of last contact' do
      within '.list' do
        expect(page.first('tr')).to have_content client_2.full_name
        expect(page.all('tr').last).to have_content client_1.full_name
      end
    end

    step 'when user enters a message that is too long' do
      fill_in 'Your message', with: too_long_message_body

      expect(page).to have_content('This message is more than 1600 characters and is too long to send.')
      expect(page).to have_button('Send', disabled: true)
      expect(page).to have_button('Send later', disabled: true)
    end

    step 'user sees character count or appropriate warning message' do
      fill_in 'Your message', with: long_message_body

      expect(page.find('.new_mass_message .character-count')).to have_content('Because of its length, this message may be sent as 2 texts')
      expect(page).to have_button('Send', disabled: false)
      expect(page).to have_button('Send later', disabled: false)
    end

    step 'user can select all clients' do
      check 'Select all'

      expect(find('#select_all')['checked']).to eq 'true'

      id1 = ReportingRelationship.find_by(client: Client.find_by(phone_number: client_1.phone_number), user: user).id
      id2 = ReportingRelationship.find_by(client: Client.find_by(phone_number: client_2.phone_number), user: user).id
      id3 = ReportingRelationship.find_by(client: Client.find_by(phone_number: client_3.phone_number), user: user).id

      expect(find("#mass_message_reporting_relationships_#{id1}")['checked']).to eq('true')
      expect(find("#mass_message_reporting_relationships_#{id2}")['checked']).to eq('true')
      expect(find("#mass_message_reporting_relationships_#{id3}")['checked']).to eq('true')

      find('tr', text: client_1.full_name).click
      expect(find('#select_all')['checked']).to eq(nil)
    end

    step 'user sorts clients' do
      find('th', text: 'Name').click
      expect(page).to have_content(/#{client_1.full_name}.*#{client_2.full_name}.*#{client_3.full_name}/)
      find('th', text: 'Name').click
      expect(page).to have_content(/#{client_3.full_name}.*#{client_2.full_name}.*#{client_1.full_name}/)
    end

    step 'user searches for clients' do
      fill_in 'Search clients by name', with: 'a'
      expect(page).to have_content client_1.full_name
      expect(page).to_not have_content client_2.full_name
      expect(page).to_not have_content client_3.full_name

      click_on 'clear_search'
      expect(page).to have_content client_1.full_name
      expect(page).to have_content client_2.full_name
      expect(page).to have_content client_3.full_name
    end

    step 'then user sends message' do
      perform_enqueued_jobs do
        click_on 'Send'
        expect(page).to have_current_path(clients_path)
        expect(page).to have_css '.flash__message', text: I18n.t('flash.notices.mass_message.sent'), visible: :all
      end
    end

    step 'then messages were sent to client 1 and 3' do
      expect(Message.where(body: long_message_body).count).to eq 2
      expect(Client.find_by(phone_number: client_2.phone_number).messages.last.body).to eq long_message_body
      expect(Client.find_by(phone_number: client_3.phone_number).messages.last.body).to eq long_message_body
    end

    step 'user navigates back to the mass messages page' do
      click_on 'Mass message'
      expect(page).to have_content 'New mass message'
    end

    step 'user fills in message and selects clients' do
      fill_in 'Your message', with: scheduled_message_body

      check client_1.full_name
      check client_2.full_name
    end

    step 'user clicks the send later button, revealing the scheduling form' do
      expect(page).to_not have_content I18n.t('views.mass_message.new.schedule_form.title')
      click_on 'Send later'
      expect(page).to have_content I18n.t('views.mass_message.new.schedule_form.title')
    end

    step 'when user enters a message that is too long' do
      fill_in 'Your message', with: too_long_message_body

      expect(page).to have_content('This message is more than 1600 characters and is too long to send.')
      expect(page).to have_button('Schedule messages', disabled: true)
    end

    step 'user selects a date in the past and tries to schedule the message' do
      fill_in 'Your message', with: scheduled_message_body
      past_date = (Time.zone.today - 1.month).beginning_of_month

      fill_in 'Date', with: ''
      find('.ui-datepicker-prev').click
      click_on past_date.strftime('%-d')
      select past_date.change(min: 0).strftime('%-l:%M%P'), from: 'Time'
      click_on 'Schedule messages'
      expect(page).to have_current_path(mass_messages_path)
      expect(page).to have_content I18n.t('views.mass_message.new.schedule_form.title')
      expect(page).to have_content I18n.t('activerecord.errors.models.message.attributes.send_at.on_or_after')
    end

    step 'user selects a date in the future and schedules the message' do
      future_date = (Time.zone.today + 1.month).beginning_of_month

      fill_in 'Date', with: ''
      find('.ui-datepicker-next').click
      find('.ui-datepicker-next').click
      click_on future_date.strftime('%-d')
      select future_date.change(min: 0).strftime('%-l:%M%P'), from: 'Time'

      perform_enqueued_jobs do
        click_on 'Schedule messages'
      end

      expect(page).to have_current_path(clients_path)
      expect(page).to have_css '.flash__message', text: I18n.t('flash.notices.mass_message.scheduled'), visible: :all
    end
  end
end
