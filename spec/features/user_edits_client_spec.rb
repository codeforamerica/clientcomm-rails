require 'rails_helper'

feature 'logged-out user visits manage client page' do
  scenario 'and is redirected to the login form' do
    myuser = create :user
    clientone = create :client, user: myuser
    visit edit_client_path(clientone.id)
    expect(page).to have_text 'Log in'
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'user edits client', :js do
  let(:myuser) { create :user }
  let!(:clientone) { create :client, user: myuser }

  before do
    login_as myuser, :scope => :user
    visit root_path
  end

  scenario 'successfully' do
    within "#client_#{clientone.id}" do
      find('td', text: 'Manage').click
    end
    expect(page).to have_current_path(edit_client_path(clientone))

    new_first_name = 'Vinicius'
    new_last_name = 'Lima'
    note = 'Here is a note.'

    fill_in 'First name', with: new_first_name
    fill_in 'Last name', with: new_last_name
    fill_in 'Notes', with: note

    click_on 'Save changes'
    expect(page).to have_current_path(client_messages_path(clientone))

    expect(page).to have_content "#{new_first_name} #{new_last_name}"

    click_on 'Manage client'

    expect(find_field('Notes').value).to eq note
  end

  scenario 'and fails validation' do
    within("#client_#{clientone.id}") do
      find('td', text: 'Manage').click
    end
    expect(page).to have_current_path(edit_client_path(clientone))
    fill_in 'Last name', with: ''
    click_on 'Save changes'
    expect(page).to have_content 'Edit client'
    expect(page).to have_content "Last name can't be blank"
  end
end
