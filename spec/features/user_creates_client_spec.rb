require 'rails_helper'

feature 'logged-out user visits create client page' do
  scenario 'and is redirected to the login form' do
    visit new_client_path
    expect(page).to have_text 'Log in'
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'User creates client' do
  before do
    myuser = create :user
    login_as(myuser, :scope => :user)
    visit root_path
    click_on 'New client'
    expect(page).to have_current_path(new_client_path)
  end

  scenario 'successfully', :js do
    myclient = build :client, notes: 'some note', first_name: 'Jean', last_name: 'Grey'
    add_client(myclient)
    expect(page).to have_content 'Jean Grey'
    click_on 'Manage client'

    expect(find_field('Notes').value).to eq myclient.notes
  end

  scenario 'unsuccessfully' do
    myclient = build :client, last_name: nil

    fill_in 'First name', with: myclient.first_name
    fill_in 'Last name', with: myclient.last_name
    fill_in 'Phone number', with: myclient.phone_number
    fill_in 'Notes', with: myclient.notes
    click_on 'Save new client'
    expect(page).to have_content 'Add a new client'
    expect(page).to have_content "Last name can't be blank"
  end

  context 'client status feature flag enabled' do
    before do
      FeatureFlag.create!(flag: 'client_status', enabled: true)
    end

    scenario 'client status is selected' do
      create :client_status, name: 'Active'
      create :client_status, name: 'Training'
      create :client_status, name: 'Exited'

      myclient = build :client, client_status: ClientStatus.find_by_name('Exited')

      visit new_client_path

      fill_in 'First name', with: myclient.first_name
      fill_in 'Last name', with: myclient.last_name
      fill_in 'Phone number', with: myclient.phone_number
      choose myclient.client_status.name
      click_on 'Save new client'

      expect(page).to have_content myclient.first_name
      click_on 'Manage client'
      expect(find_field('Exited')).to be_checked
    end
  end
end
