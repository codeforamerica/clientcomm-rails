require "rails_helper"

feature "logged-out user visits clients page" do
  scenario "and sees only clients they have created" do
    # login as a user
    user1 = create :user
    login(user1)
    # create a new client
    client1 = build :client
    add_client(client1)
    # logout
    click_on "Sign out"
    # login as a different user
    user2 = create :user
    login(user2)
    # add my own client
    client2 = build :client
    add_client(client2)
    # we're on the clients page
    expect(page).to have_current_path(clients_path)
    # the client I just created should be in the list
    expect(page).to have_css '.data-table td', text: client2.first_name + " " + client2.last_name
    # but the client user1 created shouldn't be
    expect(page).not_to have_css '.data-table td', text: client1.first_name + " " + client1.last_name
  end
end
