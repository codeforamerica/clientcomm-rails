require "rails_helper"

feature "user archives client" do
  let(:myuser) { create :user }

  before do
    login_as myuser, scope: :user
  end

  scenario "user clicks archive client button" do
    clientone = create :client, user: myuser, first_name: 'Luke', last_name: 'Skywalker'
    visit root_path
    click_on 'Luke Skywalker'
    click_on 'Manage client'
    expect(page).to have_current_path(edit_client_path(clientone))

    expect(page).to have_content 'Delete client'

    click_on 'Delete Luke Skywalker'

    expect(page).to have_content 'Client successfully deleted'
    click_link 'Home'

    expect(page).to have_current_path(clients_path)
    expect(page).to_not have_content 'Luke Skywalker'
  end

  scenario "archived client is revived by incoming sms" do
    clientone = create :client, user: myuser, active: false, phone_number: twilio_new_message_params['From']
    visit root_path
    expect(page).to_not have_content "#{clientone.first_name} #{clientone.last_name}"
    twilio_post_sms
    visit root_path
    expect(page).to have_content "#{clientone.first_name} #{clientone.last_name}"
  end
end
