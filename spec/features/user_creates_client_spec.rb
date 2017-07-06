require "rails_helper"

feature "logged-out user visits create client page" do
  scenario "and is redirected to the login form" do
    visit new_client_path
    expect(page).to have_text "Log in"
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature "User creates client" do
  before do
    myuser = create :user
    login_as(myuser, :scope => :user)
    visit root_path
    click_on 'New client'
    expect(page).to have_current_path(new_client_path)
  end

  scenario 'successfully' do
    myclient = build :client
    add_client(myclient)
    expect(page).to have_css '.data-table td', text: myclient.full_name
    expect(page).to have_current_path(clients_path)
  end

  scenario 'unsuccessfully' do
    myclient = build :client, last_name: nil

    add_client(myclient)
    expect(page).to have_content 'Add a new client'
    expect(page).to have_content "Last name can't be blank"
  end
end
