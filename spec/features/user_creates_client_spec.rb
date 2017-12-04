require 'rails_helper'

feature 'logged-out user visits create client page' do
  scenario 'and is redirected to the login form' do
    visit new_client_path
    expect(page).to have_text 'Log in'
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'User creates client' do
  let(:myuser) { create :user }
  let(:first_name) { 'Waffles' }
  let(:last_name) { 'McGee' }
  let(:notes) { 'some notes' }
  let(:phone_number) { '+12345678910' }

  before do
    login_as(myuser, :scope => :user)
    visit root_path
    click_on 'New client'
    expect(page).to have_current_path(new_client_path)
  end

  scenario 'successfully', :js do
    fill_in 'First name', with: first_name
    fill_in 'Last name', with: last_name
    fill_in 'Phone number', with: phone_number
    fill_in 'Notes', with: notes
    click_on 'Save new client'

    expect(page).to have_content first_name
    expect(page).to have_content last_name
    click_on 'Manage client'

    expect(find_field('Notes').value).to eq notes
  end

  scenario 'unsuccessfully' do
    fill_in 'First name', with: first_name
    fill_in 'Last name', with: ''
    fill_in 'Phone number', with: phone_number
    fill_in 'Notes', with: notes
    click_on 'Save new client'
    expect(page).to have_content 'Add a new client'
    expect(page).to have_content "Last name can't be blank"
  end

  context 'client status feature flag enabled' do
    let!(:status) { create :client_status, name: 'Active' }
    before do
      FeatureFlag.create!(flag: 'client_status', enabled: true)
    end

    scenario 'client status is selected' do
      visit new_client_path

      fill_in 'First name', with: first_name
      fill_in 'Last name', with: last_name
      fill_in 'Phone number', with: phone_number
      choose status.name
      click_on 'Save new client'

      expect(page).to have_content first_name
      click_on 'Manage client'
      expect(find_field('Active')).to be_checked
    end
  end
end
