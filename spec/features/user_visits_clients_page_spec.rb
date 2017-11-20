require 'rails_helper'

feature 'logged-out user visits clients page' do
  scenario 'and is redirected to the login form' do
    visit clients_path
    expect(page).to have_text 'Log in'
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'manage action is hidden on mobile', js: true do
  scenario 'user visits client list on mobile' do
    myuser = create :user
    create :client, user: myuser
    login_as(myuser, :scope => :user)

    visit clients_path
    resize_window_to_mobile
    expect(page).to_not have_text 'Manage'
    expect(page).to_not have_text 'Action'
    resize_window_to_default
  end
end

feature 'logged-in user visits clients page' do
  scenario 'successfully' do
    myuser = create :user
    login(myuser)
  end
end
