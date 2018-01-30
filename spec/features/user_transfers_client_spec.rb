require 'rails_helper'

feature 'user transfers client', :js, active_job: true do
  let!(:myuser) { create :user }
  let!(:transfer_user) { create :user, department: myuser.department }
  let!(:unclaimed_user) { create :user, department: myuser.department }
  let!(:other_user) { create :user }
  let!(:clientone) { create :client, user: myuser }

  let(:note) { 'I am transfering this client to you' }

  before do
    myuser.department.update(user_id: unclaimed_user.id)
    other_user.clients << clientone
    login_as myuser, :scope => :user
    visit root_path
  end

  scenario 'successfully' do
    expect(page).to have_content clientone.full_name

    within "#client_#{clientone.id}" do
      find('td', text: 'Manage').click
    end
    expect(page).to have_current_path(edit_client_path(clientone))
    expect(page).to have_content("also assigned to #{other_user.full_name}")
    expect(page).to_not have_css 'select#reporting_relationship_user_id', text: myuser.full_name
    unclaimed_user = User.find(myuser.department.user_id)
    expect(page).to_not have_css 'select#reporting_relationship_user_id', text: unclaimed_user.full_name
    select transfer_user.full_name, from: 'reporting_relationship_user_id'
    fill_in 'transfer_note', with: note

    perform_enqueued_jobs do
      click_on "Transfer #{clientone.full_name}"
    end

    emails = ActionMailer::Base.deliveries

    expect(emails.count).to eq 1
    expect(emails.first.html_part.to_s).to include clientone.full_name
    expect(emails.first.html_part.to_s).to include clientone.phone_number
    expect(emails.first.html_part.to_s).to include note

    expect(page).to have_current_path(clients_path)
    expect(page).to have_css '.flash p', text: "#{clientone.full_name} was transferred to #{transfer_user.full_name}"

    expect(page).to_not have_css '#client-list', text: clientone.full_name

    login_as transfer_user, :scope => :user
    visit root_path
    expect(page).to have_content clientone.full_name
  end
end
