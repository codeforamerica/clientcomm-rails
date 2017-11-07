require "rails_helper"

feature "search and sort clients" do
  let!(:myuser) { create :user }

  before do
    @clientone = build :client, user: myuser, first_name: 'Rachel', last_name: 'A'
    @clienttwo = build :client, user: myuser, first_name: 'Paras', last_name: 'B'
    @clientthree = build :client, user: myuser, first_name: 'Charlie', last_name: 'C'

    login_as(myuser, :scope => :user)
    travel_to 7.days.ago do
      add_client(@clientone)
    end

    travel_to 1.day.ago do
      add_client(@clienttwo)
    end

    add_client(@clientthree)

    visit clients_path
  end

  describe "user searches by name" do
    it "filters client list to match input", js: true do
      expect(page).to have_css '.data-table td', text: @clientone.full_name
      expect(page).to have_css '.data-table td', text: @clienttwo.full_name
      expect(page).to have_css '.data-table td', text: @clientthree.full_name

      fill_in "Search clients by name", with: @clientone.full_name

      expect(page).to have_css '.data-table td', text: @clientone.full_name

      expect(page).to_not have_css '.data-table td', text: @clienttwo.full_name
      expect(page).to_not have_css '.data-table td', text: @clientthree.full_name
    end

    it "shows all results when clear search button is clicked", js: true do
      expect(page).to have_css '#clear_search'

      fill_in "Search clients by name", with: @clientone.full_name

      expect(page).to have_css '.data-table td', text: @clientone.full_name

      expect(page).to_not have_css '.data-table td', text: @clienttwo.full_name
      expect(page).to_not have_css '.data-table td', text: @clientthree.full_name

      click_button("clear_search")

      expect(page).to have_css '.data-table td', text: @clientone.full_name
      expect(page).to have_css '.data-table td', text: @clienttwo.full_name
      expect(page).to have_css '.data-table td', text: @clientthree.full_name
    end

    it "shows a warning when there are no search results", js: true do
      expect(page).to_not have_css '#no-search-results'

      fill_in "Search clients by name", with: 'text-that-definitely-wont-return-results'

      expect(page).to have_css '#no-search-results'

      click_button("clear_search")

      expect(page).to_not have_css '#no-search-results'
    end
  end

  describe "user sorts clients" do
    it "sorts by most recent contact by default", js: true do
      expect(page).to have_css('.glyphicon-arrow-down')
      expect(page).to have_css('tr:first-child', text: @clientthree.full_name)
      expect(page).to have_css('tr:last-child', text: @clientone.full_name)
    end

    it "reverses list when Last contact is clicked", js: true do
      find("th", text: "Last contact").click
      expect(page).to have_css('tr:first-child', text: @clientone.full_name)
      expect(page).to have_css('tr:last-child', text: @clientthree.full_name)
    end

    it "sorts by last name", js: true do
      find("th", text: "Name").click
      expect(page).to have_css('tr:first-child', text: @clientone.full_name)
      expect(page).to have_css('tr:last-child', text: @clientthree.full_name)

      find("th", text: "Name").click
      expect(page).to have_css('tr:first-child', text: @clientthree.full_name)
      expect(page).to have_css('tr:last-child', text: @clientone.full_name)
    end
  end
end
