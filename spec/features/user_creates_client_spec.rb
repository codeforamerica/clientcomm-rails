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
  let(:id_number) { '1234' }
  let(:notes) { 'some notes' }
  let(:phone_number) { '+12345678910' }
  let(:phone_number_display) { '(234) 567-8910' }
  let(:future_date) { Time.zone.now.change(min: 0, day: 3) + 1.month }
  before do
    FeatureFlag.create!(flag: 'client_id_number', enabled: true)
    FeatureFlag.create!(flag: 'court_dates', enabled: true)
    login_as(myuser, scope: :user)
    visit root_path
    click_on 'New client'
    expect(page).to have_current_path(new_client_path)
  end

  scenario 'successfully', :js do
    fill_in 'First name', with: first_name
    fill_in 'Last name', with: last_name
    fill_in 'Phone number', with: phone_number
    fill_in 'ID number', with: id_number
    fill_in 'Notes', with: notes
    fill_in 'Court date (optional)', with: ''
    find('.ui-datepicker-next').click
    click_on future_date.strftime('%-d')
    click_on 'Save new client'
    expect(page).to have_content first_name
    expect(page).to have_content last_name

    click_on 'Manage client'

    expect(find_field('Notes').value).to eq notes
    expect(find_field('ID number').value).to eq id_number
    expect(find_field('Court date (optional)').value).to eq future_date.strftime('%m/%d/%Y')
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

  context 'the client already exists and belongs to another user in another department' do
    let(:other_user) { create :user }
    let!(:client) { create :client, user: other_user, first_name: 'Waffles', last_name: 'MacGee', phone_number: phone_number }

    scenario 'it displays a confirmation page with the correct info' do
      step 'filling in the client info' do
        fill_in 'First name', with: first_name
        fill_in 'Last name', with: last_name
        fill_in 'Phone number', with: phone_number
        fill_in 'Notes', with: notes
        click_on 'Save new client'

        expect(page).to have_current_path(clients_path)

        expect(page).to have_content 'Waffles'
        expect(page).to have_content 'MacGee'
        expect(page).to have_content("The number #{phone_number_display} already exists in ClientComm")
        click_on 'Yes, use this client'

        rr = myuser.reporting_relationships.find_by(client: client)
        expect(page).to have_current_path(reporting_relationship_path(rr))

        click_on 'Manage client'

        expect(find_field('Notes').value).to eq notes
      end
    end
  end

  context 'client status feature flag enabled' do
    let!(:status) { create :client_status, name: 'Active', department: myuser.department }
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
