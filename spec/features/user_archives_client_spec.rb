require 'rails_helper'

feature 'user archives client', :js do
  before do
    @survey = ENV['TYPEFORM_LINK']
    ENV['TYPEFORM_LINK'] = 'candy'
    page.driver.browser.js_errors = false
  end

  after do
    ENV['TYPEFORM_LINK'] = @survey
    page.driver.browser.js_errors = true
  end

  scenario 'user clicks archive client button' do
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

    click_on "Delete #{clientone.first_name} #{clientone.last_name}"

    expect(page).to have_content 'Client successfully deleted'
    click_link 'Home'

    expect(page).to have_current_path(clients_path)
    expect(page).to_not have_content "#{clientone.first_name} #{clientone.last_name}"
  end

  scenario 'archived client is revived by incoming sms' do
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
