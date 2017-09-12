require 'rails_helper'

feature 'Admin features' do
  let!(:user) { create :user }

  scenario 'Admin disables user' do
    admin = create :admin_user

    login_as(admin, scope: :admin_user)

    visit admin_users_path

    expect(page).to have_content 'Users'

    expect(find("tr##{dom_id(user)}").text).to include 'Disable'

    within "tr##{dom_id(user)}" do
      click_on 'Disable'
    end

    expect(page).to have_content "Disable #{user.full_name}'s account"

    click_on 'Disable account'

    save_and_open_page

    expect(find("tr##{dom_id(user)}").text).not_to include 'Disable'
  end
end