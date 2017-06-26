require "rails_helper"

feature "logged-out user visits create client page" do
  scenario "and is redirected to the login form" do
    visit new_client_path
    expect(page).to have_text "Log in"
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature "User creates client" do
  scenario "successfully" do
    # log in with a fake user
    myuser = create :user
    login_as(myuser, :scope => :user)
    visit root_path
    click_on "New client"
    expect(page).to have_current_path(new_client_path)
    myclient = build :client
    add_client(myclient)
    expect(page).to have_css '.data-table td', text: myclient.full_name
    expect(page).to have_current_path(clients_path)
  end
end

feature "User edits client" do
  scenario "unsuccessfully" do
    myuser = create :user
    login_as(myuser, :scope => :user)

    myclient = create(:client, user: myuser)

    visit root_path

    within("#client_#{myclient.id}") do
      click_on 'Edit'
    end

    expect(page).to have_current_path(edit_client_path(myclient))
    fill_in 'Last name', with: ''
    click_on 'Save Changes'

    expect(page).to have_content 'Edit Client'
    expect(page).to have_content "Last name can't be blank"

    fill_in 'Last name', with: 'Lastname'
    click_on 'Save Changes'

    expect(page).to have_current_path(clients_path)
    expect(page).to have_content "#{myclient.first_name} Lastname"
  end
end
