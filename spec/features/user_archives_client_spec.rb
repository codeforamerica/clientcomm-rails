require "rails_helper"

feature "user edits client" do
  scenario "user clicks archive client button" do
    # log in with a fake user
    myuser = create :user
    clientone = create :client, user: myuser
    login_as myuser, :scope => :user
    visit root_path
    within "#client_#{clientone.id}" do
      click_on 'Manage'
    end
    expect(page).to have_current_path(edit_client_path(clientone))
    expect(page).to have_content 'Delete client'

    click_on "Delete #{clientone.first_name} #{clientone.last_name}"

    expect(page).to have_current_path(clients_path)
    expect(page).to_not have_content "#{clientone.first_name} #{clientone.last_name}"
  end
end
