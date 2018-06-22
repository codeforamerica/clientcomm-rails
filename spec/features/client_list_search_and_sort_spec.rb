require 'rails_helper'

feature 'search and sort clients' do
  let!(:myuser) { create :user }

  before do
    @clientone = build :client, first_name: 'Rachel', last_name: 'A'
    @clienttwo = build :client, first_name: 'Paras', last_name: 'B'
    @clientthree = build :client, first_name: 'Charlie', last_name: 'C'

    login_as(myuser, scope: :user)
    travel_to 7.days.ago do
      add_client(@clientone)
    end

    travel_to 1.day.ago do
      add_client(@clienttwo)
    end

    add_client(@clientthree)
  end

  subject { visit clients_path }

  let(:clientone) { Client.find_by(phone_number: @clientone.phone_number) }
  let(:clienttwo) { Client.find_by(phone_number: @clienttwo.phone_number) }
  let(:clientthree) { Client.find_by(phone_number: @clientthree.phone_number) }

  describe 'user searches by name' do
    it 'filters client list to match input', js: true do
      subject
      expect(page).to have_css '.data-table td', text: @clientone.full_name
      expect(page).to have_css '.data-table td', text: @clienttwo.full_name
      expect(page).to have_css '.data-table td', text: @clientthree.full_name

      fill_in 'Search clients by name', with: @clientone.full_name

      expect(page).to have_css '.data-table td', text: @clientone.full_name

      expect(page).to_not have_css '.data-table td', text: @clienttwo.full_name
      expect(page).to_not have_css '.data-table td', text: @clientthree.full_name
    end

    it 'shows all results when clear search button is clicked', js: true do
      subject
      expect(page).to have_css '#clear_search'

      fill_in 'Search clients by name', with: @clientone.full_name

      expect(page).to have_css '.data-table td', text: @clientone.full_name

      expect(page).to_not have_css '.data-table td', text: @clienttwo.full_name
      expect(page).to_not have_css '.data-table td', text: @clientthree.full_name

      click_button('clear_search')

      expect(page).to have_css '.data-table td', text: @clientone.full_name
      expect(page).to have_css '.data-table td', text: @clienttwo.full_name
      expect(page).to have_css '.data-table td', text: @clientthree.full_name
    end

    it 'shows a warning when there are no search results', js: true do
      subject
      expect(page).to_not have_css '#no-search-results'

      fill_in 'Search clients by name', with: 'text-that-definitely-wont-return-results'

      expect(page).to have_css '#no-search-results'

      click_button('clear_search')

      expect(page).to_not have_css '#no-search-results'
    end
  end

  describe 'user sorts clients' do
    it 'sorts by most recent contact by default', js: true do
      subject
      expect(page).to have_css('.glyphicon-arrow-down')
      expect(page).to have_css('tr:first-child', text: @clientthree.full_name)
      expect(page).to have_css('tr:last-child', text: @clientone.full_name)
    end

    it 'reverses list when Last contact is clicked', js: true do
      subject
      find('th', text: 'Last contact').click
      expect(page).to have_css('tr:first-child', text: @clientone.full_name)
      expect(page).to have_css('tr:last-child', text: @clientthree.full_name)
    end

    it 'sorts by last name', js: true do
      subject
      find('th', text: 'Name').click
      expect(page).to have_css('tr:first-child', text: @clientone.full_name)
      expect(page).to have_css('tr:last-child', text: @clientthree.full_name)

      find('th', text: 'Name').click
      expect(page).to have_css('tr:first-child', text: @clientthree.full_name)
      expect(page).to have_css('tr:last-child', text: @clientone.full_name)
    end

    context 'court dates flag is enabled' do
      before do
        FeatureFlag.create!(flag: 'court_dates', enabled: true)
        clientone.update!(next_court_date_at: Date.new(2018, 7, 21))
        clientthree.update!(next_court_date_at: Date.new(2018, 8, 17))
      end

      it 'sorts by court date', js: true do
        subject
        find('th', text: 'Court date').click
        expect(page).to have_css('tr:first-child', text: @clientone.full_name)
        expect(page).to have_css('tr:nth-child(2)', text: @clientthree.full_name)

        find('th', text: 'Court date').click
        expect(page).to have_css('tr:nth-child(2)', text: @clientthree.full_name)
        expect(page).to have_css('tr:last-child', text: @clientone.full_name)
      end
    end
    context 'has scheduled messages' do
      let(:clientfour) { create :client, user: myuser, first_name: 'Charlie', last_name: 'D' }

      before do
        FeatureFlag.create!(flag: 'scheduled_message_count', enabled: true)

        create_list :text_message, 10, reporting_relationship: clienttwo.reporting_relationships.find_by(user: myuser), send_at: Time.zone.now + 1.day
        create_list :text_message, 2, reporting_relationship: clientthree.reporting_relationships.find_by(user: myuser), send_at: Time.zone.now + 1.day
        create_list :text_message, 1, reporting_relationship: clientfour.reporting_relationships.find_by(user: myuser), send_at: Time.zone.now + 1.day
      end

      it 'sorts by court date', js: true do
        subject
        find('th', text: 'Scheduled messages').click
        expect(page).to have_css('tr:first-child td.scheduled-message-count', text: '')
        expect(page).to have_css('tr:nth-child(2) td.scheduled-message-count div.purple-circle', text: '')
        expect(page).to have_css('tr:nth-child(3) td.scheduled-message-count div.purple-circle', text: '2')
        expect(page).to have_css('tr:nth-child(4) td.scheduled-message-count div.purple-circle', text: '...')

        find('th', text: 'Scheduled messages').click
        expect(page).to have_css('tr:first-child td.scheduled-message-count div.purple-circle', text: '...')
        expect(page).to have_css('tr:nth-child(2) td.scheduled-message-count div.purple-circle', text: '2')
        expect(page).to have_css('tr:nth-child(3) td.scheduled-message-count div.purple-circle', text: '')
        expect(page).to have_css('tr:nth-child(4) td.scheduled-message-count', text: '')
      end

      it 'sorts by court date and timestamp', js: true do
        create_list :text_message, 8, reporting_relationship: clientthree.reporting_relationships.find_by(user: myuser), send_at: Time.zone.now + 1.day
        subject
        find('th', text: 'Scheduled messages').click
        expect(page).to have_css('tr:nth-child(3)', text: clienttwo.full_name)
        expect(page).to have_css('tr:nth-child(4)', text: clientthree.full_name)
        find('th', text: 'Scheduled messages').click
        expect(page).to have_css('tr:first-child', text: clientthree.full_name)
        expect(page).to have_css('tr:nth-child(2)', text: clienttwo.full_name)
      end
    end
  end
end
