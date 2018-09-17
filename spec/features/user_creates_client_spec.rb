require 'rails_helper'

feature 'logged-out user visits create client page' do
  scenario 'and is redirected to the login form' do
    visit new_client_path
    expect(page).to have_text 'Log in'
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'User creates client' do
  let(:user_first_name) { 'Roman' }
  let(:user_last_name) { 'Mirga' }
  let(:myuser) { create :user, full_name: "#{user_first_name} #{user_last_name}" }
  let(:client_first_name) { 'Waffles' }
  let(:client_last_name) { 'McGee' }
  let(:id_number) { '1234' }
  let(:notes) { 'some notes' }
  let(:phone_number) { '+12345678910' }
  let(:phone_number_display) { '(234) 567-8910' }
  let(:future_date) { Time.zone.now.change(min: 0, day: 3) + 1.month }

  before do
    FeatureFlag.create!(flag: 'client_id_number', enabled: true)
    FeatureFlag.create!(flag: 'court_dates', enabled: true)
    login_as(myuser, scope: :user)
    visit root_path
    click_on 'New client'
    expect(page).to have_current_path(new_client_path)
  end

  scenario 'successfully', :js do
    fill_in 'First name', with: client_first_name
    fill_in 'Last name', with: client_last_name
    fill_in 'Phone number', with: phone_number
    fill_in 'ID number', with: id_number
    fill_in 'Notes', with: notes
    fill_in 'Court date (optional)', with: ''
    find('.ui-datepicker-next').click
    click_on future_date.strftime('%-d')
    click_on 'Save new client'
    expect(page).to have_content client_first_name
    expect(page).to have_content client_last_name

    click_on 'Manage client'

    expect(find_field('Notes').value).to eq notes
    expect(find_field('ID number').value).to eq id_number
    expect(find_field('Court date (optional)').value).to eq future_date.strftime('%m/%d/%Y')
  end

  scenario 'unsuccessfully' do
    fill_in 'First name', with: client_first_name
    fill_in 'Last name', with: ''
    fill_in 'Phone number', with: phone_number
    fill_in 'Notes', with: notes
    click_on 'Save new client'
    expect(page).to have_content 'Add a new client'
    expect(page).to have_content "Last name can't be blank"
  end

  context 'the client already exists and belongs to another user in another department' do
    let(:other_user) { create :user }
    let(:other_client_first_name) { 'Pancakes' }
    let(:other_client_last_name) { 'Stephanopoulos' }
    let!(:client) { create :client, user: other_user, first_name: other_client_first_name, last_name: other_client_last_name, phone_number: phone_number }

    scenario 'it displays a confirmation page with the correct info' do
      step 'filling in the client info' do
        fill_in 'First name', with: client_first_name
        fill_in 'Last name', with: client_last_name
        fill_in 'Phone number', with: phone_number
        fill_in 'Notes', with: notes
        click_on 'Save new client'

        expect(page).to have_current_path(clients_path)

        expect(page).to have_content other_client_first_name
        expect(page).to have_content other_client_last_name
        expect(page).to have_content("The number #{phone_number_display} already exists in ClientComm")
        click_on 'Yes, use this client'

        rr = myuser.reporting_relationships.find_by(client: client)
        expect(page).to have_current_path(reporting_relationship_path(rr))

        click_on 'Manage client'

        expect(find_field('Notes').value).to eq notes
      end
    end
  end

  context 'user is in welcome message treatment group' do
    let(:too_long_message_body) { 'bye ' * 401 }

    before do
      myuser.update(treatment_group: 'baltimore-welcome-message')
    end

    scenario 'welcome message page is shown after client is created', :js, active_job: true do
      welcome_body = I18n.t(
        'message.welcome',
        salutation: 'Good morning',
        client_full_name: "#{client_first_name} #{client_last_name}",
        user_last_name: user_last_name
      )

      step 'fills in and submits new client info and sees the welcome message page' do
        travel_to Time.zone.now.noon - 1.hour do
          visit new_client_path

          fill_in 'First name', with: client_first_name
          fill_in 'Last name', with: client_last_name
          fill_in 'Phone number', with: phone_number
          click_on 'Save new client'

          expect(page).to have_current_path(new_reporting_relationship_welcome_path(myuser.reload.reporting_relationships.last))
          expect(page).to have_content("Introduce yourself to #{client_first_name} #{client_last_name}")
          expect(page).to have_css('#message_body', text: welcome_body)
          expect(page).to have_button('Send', disabled: false)
        end
      end

      rr = myuser.reload.reporting_relationships.last

      step 'clicks the reveal widget' do
        expect(page).to_not have_content("ClientComm data shows that some factors contribute positively to a message's rate of response.")
        click_on 'reveal-button'
        expect(page).to have_content("ClientComm data shows that some factors contribute positively to a message's rate of response.")
      end

      step 'enters an empty message and the send button is disabled' do
        fill_in 'message_body', with: ''
        expect(page).to have_button('Send', disabled: true)
      end

      step 'enters a too-long message and the send button is disabled' do
        fill_in 'Send a text message', with: too_long_message_body
        expect(page).to have_button('Send', disabled: true)
      end

      step 'clicks skip button and is redirected to the conversation' do
        click_on 'Skip'
        expect(page).to have_current_path(reporting_relationship_path(rr))
        expect(page).to_not have_css '.message--outbound'
        expect(page).to_not have_css '.message--inbound'
      end

      step 'submits welcome message form and sees the outgoing message in the conversation' do
        travel_to Time.zone.now.noon - 1.hour do
          visit new_reporting_relationship_welcome_path rr
          expect(page).to have_css('#message_body', text: welcome_body)
        end
        perform_enqueued_jobs do
          click_on 'Send'
          expect(page).to have_current_path(reporting_relationship_path(rr))
          expect(page).to have_css '.message--outbound div', text: welcome_body
        end
      end
    end
  end

  context 'client status feature flag enabled' do
    let!(:status) { create :client_status, name: 'Active', department: myuser.department }
    before do
      FeatureFlag.create!(flag: 'client_status', enabled: true)
    end

    scenario 'client status is selected' do
      visit new_client_path

      fill_in 'First name', with: client_first_name
      fill_in 'Last name', with: client_last_name
      fill_in 'Phone number', with: phone_number
      choose status.name
      click_on 'Save new client'

      expect(page).to have_content client_first_name
      click_on 'Manage client'
      expect(find_field('Active')).to be_checked
    end
  end
end
