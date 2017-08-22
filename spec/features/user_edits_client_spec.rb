require "rails_helper"

feature "logged-out user visits manage client page" do
  scenario "and is redirected to the login form" do
    myuser = create :user
    clientone = create :client, user: myuser
    visit edit_client_path(clientone.id)
    expect(page).to have_text "Log in"
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'user edits client' do
  before do
    myuser = create :user
    clientone = create :client, user: myuser, first_name: 'Luke', last_name: 'Skywalker'
    login_as myuser, :scope => :user
    visit root_path
    click_on 'Luke Skywalker'
    click_on 'Manage client'
    expect(page).to have_current_path(edit_client_path(clientone))
  end

  scenario "successfully" do
    new_first_name = 'Vinicius'
    new_last_name = 'Lima'
    fill_in 'First name', with: new_first_name
    fill_in 'Last name', with: new_last_name
    click_on 'Save changes'
    expect(page).to have_current_path(clients_path)
    expect(page).to have_content "#{new_first_name} #{new_last_name}"
  end

  scenario "and fails validation" do
    fill_in 'Last name', with: ''
    click_on 'Save changes'
    expect(page).to have_content 'Edit client'
    expect(page).to have_content "Last name can't be blank"
  end
end
