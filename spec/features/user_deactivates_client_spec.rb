require 'rails_helper'

feature 'user deactivates client', :js do
  let(:question_text) { 'What was the outcome for this client?' }
  let(:response_text1) { 'Successful closeout' }
  let(:response_text2) { 'FTA' }
  let(:response_text3) { 'Supervision rescinded' }
  let(:survey_question) { create :survey_question, text: question_text }
  let!(:survey_response1) { create :survey_response, survey_question: survey_question, text: response_text1 }
  let!(:survey_response2) { create :survey_response, survey_question: survey_question, text: response_text2 }
  let!(:survey_response3) { create :survey_response, survey_question: survey_question, text: response_text3 }
  let(:department) { create :department, phone_number: twilio_new_message_params['To'] }
  let(:user) { create :user, department: department }
  let(:client_active) { true }
  let!(:client) { create :client, user: user, active: client_active, phone_number: twilio_new_message_params['From'] }

  before do
    login_as user, scope: :user
    visit root_path
  end

  scenario 'user clicks deactivate client button' do
    expect(page).to have_css '#client-list', text: "#{client.first_name} #{client.last_name}"

    within "#client_#{client.id}" do
      find('td', text: 'Manage').click
    end
    expect(page).to have_current_path(edit_client_path(client))
    expect(page).to have_content 'Deactivate client'

    expect(page).to_not have_content question_text

    click_on "Deactivate #{client.first_name} #{client.last_name}"
    expect(page).to have_current_path(edit_client_path(client))

    expect(page).to have_content question_text
    expect(page).to have_content response_text1
    expect(page).to have_content response_text2
    expect(page).to have_content response_text3

    expect(page).to have_button("Deactivate #{client.first_name} #{client.last_name}", disabled: true)

    check response_text1
    check response_text3

    click_on "Deactivate #{client.first_name} #{client.last_name}"
    expect(page).to have_current_path(clients_path)
    expect(page).to_not have_css '#client-list', text: "#{client.first_name} #{client.last_name}"
    expect(page).to have_css '.flash p', text: I18n.t('flash.notices.client.deactivated', client_full_name: client.full_name)
  end

  context 'client is not active' do
    let(:client_active) { false }

    scenario 'deactivated client is revived by incoming sms' do
      expect(page).to_not have_content "#{client.first_name} #{client.last_name}"
      twilio_post_sms
      visit root_path
      expect(page).to have_content "#{client.first_name} #{client.last_name}"
    end
  end

  context 'client has a court date set' do
    before do
      FeatureFlag.create!(flag: 'court_dates', enabled: true)
      client.update!(next_court_date_at: Time.zone.now + 1.month)
      visit edit_client_path(client)
    end

    scenario 'client is deactivated successfully' do
      click_on "Deactivate #{client.first_name} #{client.last_name}"
      check response_text1
      check response_text3
      click_on "Deactivate #{client.first_name} #{client.last_name}"
      expect(page).to have_current_path(clients_path)
      expect(page).to_not have_css '#client-list', text: "#{client.first_name} #{client.last_name}"
      expect(page).to have_css '.flash p', text: I18n.t('flash.notices.client.deactivated', client_full_name: client.full_name)
    end
  end
end
