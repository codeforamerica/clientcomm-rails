require 'rails_helper'

feature 'Admin features' do
  let!(:user) { create :user }

  scenario 'Admin disables user' do
    step 'log in to admin panel' do
      admin = create :admin_user
      login_as(admin, scope: :admin_user)

      visit admin_users_path
      expect(page).to have_content 'Users'
    end

    step 'admin disables user' do
      expect(find("tr##{dom_id(user)}").text).to include 'Disable'

      within "tr##{dom_id(user)}" do
        click_on 'Disable'
      end
    end

    step 'admin confirms the disable action' do
      expect(page).to have_content "Disable #{user.full_name}'s account"
      click_on 'Disable account'
    end

    step 'admin returns to the list of users' do
      expect(page).to have_content 'Users'
    end

    step 'admin re-enables user' do
      expect(find("tr##{dom_id(user)}").text).to include 'Enable'

      within "tr##{dom_id(user)}" do
        click_on 'Enable'
      end

      expect(find("tr##{dom_id(user)}").text).to include 'Disable'
    end
  end
end
