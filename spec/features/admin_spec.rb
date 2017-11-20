require 'rails_helper'

feature 'Admin features' do
  scenario 'Admin disables user' do
    step 'given there is an active user with clients' do
      @user1 = create :user, full_name: 'User One', active: true
      @client = create :client, user: @user1, active: true
      @archived_client = create :client, user: @user1, active: false
    end

    step 'given there is a second user to transfer to' do
      @user2 = create :user, active: true
    end

    step 'log in to admin panel' do
      admin = create :admin_user
      login_as(admin, scope: :admin_user)

      visit admin_users_path
      expect(page).to have_content 'Users'
    end

    step 'admin cannot disable user with active clients' do
      expect(find("tr##{dom_id(@user1)}").text).to include 'Disable'

      within "tr##{dom_id(@user1)}" do
        click_on 'Disable'
      end

      expect(page).to have_content "Disable #{@user1.full_name}'s account"
      expect(page).to have_content 'This user has active clients.'
    end

    step 'admin transfers active clients' do
      click_on 'Clients'
      expect(page).to have_css('#page_title', text: 'Clients')

      within "tr##{dom_id(@client)}" do
        click_on 'Edit'
      end

      expect(page).to have_content 'Edit Client'

      expect(page).to have_select("user_in_dept_#{@user1.department.id}",
                                  selected: @user1.full_name)

      select @user2.full_name, from: "user_in_dept_#{@user2.department.id}"

      click_on 'Update Client'
    end

    step 'user2 receives email for transfer' do
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to contain_exactly @user2.email
      expect(mail.html_part.to_s).to include 'An administrator has transferred'
    end

    step 'admin navigates to user panel' do
      click_on 'Users'

      expect(page).to have_css('#page_title', text: 'Users')
    end

    step 'admin disables user' do
      expect(find("tr##{dom_id(@user1)}").text).to include 'Disable'

      within "tr##{dom_id(@user1)}" do
        click_on 'Disable'
      end
    end

    step 'admin confirms the disable action' do
      expect(page).to have_content "Disable #{@user1.full_name}'s account"
      click_on 'Disable account'
    end

    step 'admin returns to the list of users' do
      expect(page).to have_content 'Users'
    end

    step 'archived client is transferred to unclaimed account' do
      click_on 'Clients'

      expect(page).to have_css('#page_title', text: 'Clients')

      expect(find("tr##{dom_id(@archived_client)}").text).to include @unclaimed_account.full_name
    end

    step 'admin re-enables user' do
      click_on 'Users'

      expect(page).to have_css('#page_title', text: 'Users')

      expect(find("tr##{dom_id(@user1)}").text).to include 'Enable'

      within "tr##{dom_id(@user1)}" do
        click_on 'Enable'
      end

      expect(find("tr##{dom_id(@user1)}").text).to include 'Disable'
    end
  end
end
