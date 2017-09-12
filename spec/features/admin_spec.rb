require 'rails_helper'

feature 'Admin features' do
  scenario 'Admin disables user' do
    step 'given there is an active user with clients' do
      @user_1 = create :user, active: true
      @client = create :client, user: @user_1, active: true
      archived_client = create :client, user: @user_1, active: false
    end

    step 'given there is a second user to transfer to' do
      @user_2 = create :user, active: true, full_name: 'Cat Stevens'
    end

    step 'log in to admin panel' do
      admin = create :admin_user
      login_as(admin, scope: :admin_user)

      visit admin_users_path
      expect(page).to have_content 'Users'
    end

    step 'admin cannot disable user with active clients' do
      expect(find("tr##{dom_id(@user_1)}").text).to include 'Disable'

      within "tr##{dom_id(@user_1)}" do
        click_on 'Disable'
      end

      expect(page).to have_content "Disable #{@user_1.full_name}'s account"
      expect(page).to have_content 'This user has active clients assigned to them.'
    end

    step 'admin transfers active clients' do
      click_on 'Clients'
      expect(page).to have_css('#page_title', text: 'Clients')

      within "tr##{dom_id(@client)}" do
        click_on 'Edit'
      end

      expect(page).to have_content 'Edit Client'
      select @user_2.full_name, from: 'client_user_id'
      click_on 'Update Client'
    end

    step 'admin navigates to user panel' do
      click_on 'Users'

      expect(page).to have_css('#page_title', text: 'Users')
    end

    step 'admin disables user' do
      expect(find("tr##{dom_id(@user_1)}").text).to include 'Disable'

      within "tr##{dom_id(@user_1)}" do
        click_on 'Disable'
      end
    end

    step 'admin confirms the disable action' do
      expect(page).to have_content "Disable #{@user_1.full_name}'s account"
      click_on 'Disable account'
    end

    step 'admin returns to the list of users' do
      expect(page).to have_content 'Users'
    end

    step 'admin re-enables user' do
      expect(find("tr##{dom_id(@user_1)}").text).to include 'Enable'

      within "tr##{dom_id(@user_1)}" do
        click_on 'Enable'
      end

      expect(find("tr##{dom_id(@user_1)}").text).to include 'Disable'
    end
  end
end
