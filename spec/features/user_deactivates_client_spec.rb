require 'rails_helper'

feature 'user deactivates client', :js do
  let(:question_text) { 'What was the outcome for this client?' }
  let(:response_text1) { 'Successful closeout' }
  let(:response_text2) { 'FTA' }
  let(:response_text3) { 'Supervision rescinded' }

  before do
    page.driver.browser.js_errors = false
    survey_question = create :survey_question, text: question_text
    create :survey_response, survey_question: survey_question, text: response_text1
    create :survey_response, survey_question: survey_question, text: response_text2
    create :survey_response, survey_question: survey_question, text: response_text3
  end

  after do
    page.driver.browser.js_errors = true
  end

  scenario 'user clicks delete client button' do
    # log in with a fake user
    myuser = create :user
    clientone = create :client, user: myuser
    login_as myuser, :scope => :user
    visit root_path
    within "#client_#{clientone.id}" do
      find('td', text: 'Manage').click
    end
    expect(page).to have_current_path(edit_client_path(clientone))
    expect(page).to have_content 'Delete client'

    expect(page).to_not have_content question_text

    click_on "Delete #{clientone.first_name} #{clientone.last_name}"
    expect(page).to have_current_path(edit_client_path(clientone))

    expect(page).to have_content question_text
    expect(page).to have_content response_text1
    expect(page).to have_content response_text2
    expect(page).to have_content response_text3

    click_on "Delete #{clientone.first_name} #{clientone.last_name}"
    expect(page).to have_current_path(edit_client_path(clientone))

    check response_text1
    check response_text3

    click_on "Delete #{clientone.first_name} #{clientone.last_name}"
    expect(page).to have_current_path(clients_path)
    expect(page).to_not have_content "#{clientone.first_name} #{clientone.last_name}"
    expect(page).to have_css '.flash p', text: "#{clientone.full_name} has been successfully deleted"
  end

  scenario 'deactivated client is revived by incoming sms' do
    # log in with a fake user
    department = create :department, phone_number: twilio_new_message_params['To']
    myuser = create :user, department: department
    clientone = create :client, user: myuser, active: false, phone_number: twilio_new_message_params['From']
    login_as myuser, :scope => :user
    visit root_path
    expect(page).to_not have_content "#{clientone.first_name} #{clientone.last_name}"
    twilio_post_sms
    visit root_path
    expect(page).to have_content "#{clientone.first_name} #{clientone.last_name}"
  end
end
