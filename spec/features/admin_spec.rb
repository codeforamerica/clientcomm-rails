require 'rails_helper'

feature 'Admin features' do
  before do
    @unclaimed_email = ENV['UNCLAIMED_EMAIL']
    ENV['UNCLAIMED_EMAIL'] = 'example@example.com'
  end

  after do
    ENV['UNCLAIMED_EMAIL'] = @unclaimed_email
  end

  scenario 'Admin disables user' do
    step 'given there is an active user with clients' do
      @user_1 = create :user, active: true
      @client = create :client, user: @user_1, active: true
      @archived_client = create :client, user: @user_1, active: false
      @unclaimed_account = create :user, email: ENV['UNCLAIMED_EMAIL'], full_name: 'Unclaimed'
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
      expect(page).to have_content 'This user has active clients.'
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

    step 'user_2 receives email for transfer' do
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to contain_exactly @user_2.email
      expect(mail.html_part.to_s).to include 'An administrator has transferred'
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

    step 'archived client is transferred to unclaimed account' do
      click_on 'Clients'

      expect(page).to have_css('#page_title', text: 'Clients')

      expect(find("tr##{dom_id(@archived_client)}").text).to include @unclaimed_account.full_name
    end

    step 'admin re-enables user' do
      click_on 'Users'

      expect(page).to have_css('#page_title', text: 'Users')

      expect(find("tr##{dom_id(@user_1)}").text).to include 'Enable'

      within "tr##{dom_id(@user_1)}" do
        click_on 'Enable'
      end

      expect(find("tr##{dom_id(@user_1)}").text).to include 'Disable'
    end
  end

  scenario 'Admin bulk transfers clients', :js do
    step 'given a user with multiple clients' do
      @user_1 = create :user
      @user_2 = create :user

      @client_1 = create :client, user: @user_1
      @client_2 = create :client, user: @user_1
      @client_3 = create :client, user: @user_1
      @client_4 = create :client, user: @user_1
    end

    step 'log in to admin panel and go to the clients page' do
      admin = create :admin_user
      login_as(admin, scope: :admin_user)

      visit admin_clients_path
      expect(page).to have_content 'Clients'
    end

    step 'admin selects 3 clients to transfer' do
      expect(page.find(".batch_actions_selector")).to have_css(".disabled")

      within "tr##{dom_id(@client_1)}" do
        check "batch_action_item_#{@client_1.id}"
      end

      within "tr##{dom_id(@client_2)}" do
        check "batch_action_item_#{@client_2.id}"
      end

      within "tr##{dom_id(@client_3)}" do
        check "batch_action_item_#{@client_3.id}"
      end

      expect(page.find(".batch_actions_selector")).to_not have_css(".disabled")
    end

    step 'admin clicks batch action button and selects transfer option' do
      click_on 'Batch Actions'

      expect(page).to have_css('.dropdown_menu_list_wrapper')

      click_on 'Transfer Selected'
    end

    step 'admin selects user to recieve clients' do
      expect(page).to have_content("Are you sure you want to do this?")

      within "#dialog_confirm" do
        select "#{@user_2.full_name}"
      end

      click_on 'OK'
    end

    step 'admin sees confirmation that users were transfered' do
      expect(page).to have_content("Clients transferred: 3")
    end

    step 'user_2 receives email for transfer' do
      transfer_notification = ActionMailer::Base.deliveries.find { |mail| p mail.to.include? @user_2.email }
      parsed_mail = Nokogiri.parse(transfer_notification.html_part.to_s).to_s
      expect(transfer_notification).to_not be_nil
      expect(parsed_mail).to include 'An administrator has transferred'

      [@client_1, @client_2, @client_3].each do |client|
        expect(parsed_mail).to include client.full_name
        expect(parsed_mail).to include client.phone_number
      end
    end

    step 'client users are updated in the clients table' do
      within "tr##{dom_id(@client_1)}" do
        expect(page).to have_content @user_2.full_name
      end

      within "tr##{dom_id(@client_2)}" do
        expect(page).to have_content @user_2.full_name
      end

      within "tr##{dom_id(@client_3)}" do
        expect(page).to have_content @user_2.full_name
      end

      within "tr##{dom_id(@client_4)}" do
        expect(page).to have_content @user_1.full_name
      end
    end
  end
end
