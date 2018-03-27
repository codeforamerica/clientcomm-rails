require 'rails_helper'

feature 'logged-out user visits manage client page' do
  scenario 'and is redirected to the login form' do
    myuser = create :user
    clientone = create :client, user: myuser
    visit edit_client_path(clientone.id)
    expect(page).to have_text 'Log in'
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'user edits client', :js do
  let(:myuser) { create :user }
  let(:other_user) { create :user }
  let(:phone_number) { '2024042233' }
  let(:phone_number_display) { '(202) 404-2233' }
  let!(:clientone) { create :client, user: myuser, phone_number: phone_number }
  let(:new_first_name) { 'Vinicius' }
  let(:new_last_name) { 'Lima' }
  let(:new_note) { 'Here is a note.' }
  let(:new_phone_number) { '2024042234' }
  let(:new_phone_number_display) { '(202) 404-2234' }

  before do
    other_user.clients << clientone
    login_as myuser, :scope => :user
    visit root_path
  end

  scenario 'successfully' do
    step 'navigates to edit client form' do
      within "#client_#{clientone.id}" do
        find('td', text: 'Manage').click
      end

      expect(page).to have_current_path(edit_client_path(clientone))
      expect(page).to have_content("also assigned to #{other_user.full_name}")
      expect(find_field('Phone number').value).to eq(phone_number_display)
    end

    step 'fills and submits edit client form' do
      fill_in 'First name', with: new_first_name
      fill_in 'Last name', with: new_last_name
      fill_in 'Notes', with: new_note
      fill_in 'Phone number', with: new_phone_number

      old_name = clientone.full_name
      click_on 'Save changes'

      emails = ActionMailer::Base.deliveries
      expect(emails.count).to eq 1
      expect(emails.first.html_part.to_s).to include "#{old_name}'s name is now"
    end

    step 'loads the conversation page' do
      clientone.reload
      rr = myuser.reporting_relationships.find_by(client: clientone)
      expect(page).to have_current_path(reporting_relationship_path(rr))
      expect(page).to have_content "#{new_first_name} #{new_last_name}"
      expect(page).to have_content new_phone_number_display
      expect(page).to have_css '.message--event', text: I18n.t('messages.phone_number_edited_by_you', new_phone_number: new_phone_number_display)
    end

    step 'navigates to edit client form' do
      click_on 'Manage client'
      expect(find_field('Notes').value).to eq new_note
    end
  end

  scenario 'and fails validation' do
    within("#client_#{clientone.id}") do
      find('td', text: 'Manage').click
    end
    expect(page).to have_current_path(edit_client_path(clientone))
    fill_in 'Last name', with: ''
    click_on 'Save changes'
    expect(page).to have_content 'Edit client'
    expect(page).to have_content "Last name can't be blank"
  end
end
