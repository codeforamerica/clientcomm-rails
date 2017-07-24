require "rails_helper"

feature "search clients" do
  describe "user searches by name" do
    it "filters client list to match input", js: true do
      myuser = create :user
      clientone = create :client, user: myuser
      clienttwo = create :client, user: myuser
      clientthree = create :client, user: myuser

      login_as(myuser, :scope => :user)

      visit clients_path

      expect(page).to have_css '.data-table td', text: clientone.full_name
      expect(page).to have_css '.data-table td', text: clienttwo.full_name
      expect(page).to have_css '.data-table td', text: clientthree.full_name

      fill_in "Search clients by name", with: clientone.full_name

      expect(page).to have_css '.data-table td', text: clientone.full_name

      expect(page).to_not have_css '.data-table td', text: clienttwo.full_name
      expect(page).to_not have_css '.data-table td', text: clientthree.full_name
    end

    it "shows all results when clear search button is clicked", js: true do
      myuser = create :user
      clientone = create :client, user: myuser
      clienttwo = create :client, user: myuser
      clientthree = create :client, user: myuser

      login_as(myuser, :scope => :user)

      visit clients_path

      expect(page).to have_css '#clear_search'

      fill_in "Search clients by name", with: clientone.full_name

      expect(page).to have_css '.data-table td', text: clientone.full_name

      expect(page).to_not have_css '.data-table td', text: clienttwo.full_name
      expect(page).to_not have_css '.data-table td', text: clientthree.full_name

      click_button("clear_search")

      expect(page).to have_css '.data-table td', text: clientone.full_name
      expect(page).to have_css '.data-table td', text: clienttwo.full_name
      expect(page).to have_css '.data-table td', text: clientthree.full_name
    end
  end

end

feature "sort clients" do
#  it "page is sorted by most recent contact by default" do
#    expect(page).to have_selector('.glyphicon-arrow-down', visible: true)
#  end

end
