require "rails_helper"
include ActiveJob::TestHelper

feature 'sending messages' do
  let(:message_body) {'You have an appointment tomorrow at 10am'}
  let(:client_1) { build :client }
  let(:client_2) { build :client }

  scenario 'user sends message to client', :js do
    step 'when user logs in' do
      myuser = create :user
      login_as(myuser, scope: :user)
    end

    step 'when user creates two clients' do
      travel_to 7.days.ago do
        add_client(client_1)
        add_client(client_2)
      end
    end

    step 'when user goes to messages page' do
      myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(client_1.phone_number)).id
      visit client_messages_path(client_id: myclient_id)
    end

    step 'when user sends a message' do
      fill_in 'Send a text message', with: message_body
      perform_enqueued_jobs do
        click_on 'send_message'
      end
    end

    step 'then user sees the message displayed' do
      expect(page).to have_css '.message--outbound div', text: message_body

      # get the message object and find the dom_id
      myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(client_1.phone_number)).id
      mymessage = Message.find_by(client_id: myclient_id, body: message_body)
      expect(page).to have_css '.message--outbound', id: dom_id(mymessage)
    end

    step 'when user visits the clients page' do
      visit clients_path
    end

    step 'then user sees clients sorted by last contact time' do
      savedfirstclient = Client.find_by(phone_number: PhoneNumberParser.normalize(client_1.phone_number))
      savedsecondclient = Client.find_by(phone_number: PhoneNumberParser.normalize(client_2.phone_number))
      expect(page).to have_css "tr##{dom_id(savedfirstclient)} td", text: 'less than a minute'
      expect(page).to have_css "tr##{dom_id(savedsecondclient)} td", text: '7 days'
    end
  end

  scenario 'user schedules a message to client', :js do
    step 'when user logs in' do
      myuser = create :user
      login_as(myuser, scope: :user)
    end

    step 'when user creates a clients' do
      travel_to 7.days.ago do
        add_client(client_1)
      end
    end

    step 'when user goes to messages page' do
      myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(client_1.phone_number)).id
      visit client_messages_path(client_id: myclient_id)
    end

    step 'when user schedules a message' do
      click_on 'Send later'
      expect(page).to have_content('Send message later')
      fill_in 'Your message text', with: message_body

      future_date = Time.now + 7.days
      expect(page).to have_css '#message_send_date_1i'

      select future_date.year, from: 'message_send_date_1i'
      select Date::MONTHNAMES[future_date.month], from: 'message_send_date_2i'
      select future_date.day, from: 'message_send_date_3i'
      select future_date.hour, from: 'message_send_date_4i'
      select future_date.min, from: 'message_send_date_5i'

      perform_enqueued_jobs do
        click_on 'Schedule message'
      end

      expect(page).to_not have_content('Send message later')
      expect(page).to have_content('Your message has been scheduled')
      expect(page).to have_content('1 message scheduled')
    end

    step 'then user sees the message displayed' do
      expect(page).to have_css '.message--outbound div', text: message_body

      # get the message object and find the dom_id
      myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(client_1.phone_number)).id
      mymessage = Message.find_by(client_id: myclient_id, body: message_body)
      expect(page).to have_css '.message--outbound', id: dom_id(mymessage)
    end
  end
end
