require 'rails_helper'

feature 'User clicks on client in list', :js do

  describe "and sees the messages page" do
    let!(:myuser) { create :user }
    let!(:myclient) { create :client, user: myuser }

    context 'on the client list page' do
      before do
        login_as(myuser, :scope => :user)
        visit clients_path
      end

      it 'shows client name in table list' do
        expect(page).to have_css '.data-table td', text: myclient.full_name
      end

      it 'has the correct path' do
        expect(page).to have_current_path(clients_path)
      end

      it 'clicking on the client leads to client messages path' do
        find('td', text: myclient.full_name).click
        expect(page).to have_current_path(client_messages_path(myclient))
      end
    end

    context "on the messages page" do

      before do
        login_as(myuser, :scope => :user)
        visit client_messages_path(myclient)
      end

      it 'shows the client name in the header' do
        expect(page).to have_content myclient.full_name
      end

      it 'shows the client phone number in the header' do
        expect(page).to have_content PhoneNumberParser.format_for_display(myclient.phone_number)
      end

      # get the id from the saved client record
      it 'has the correct path for the client' do
        myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(myclient.phone_number)).id
        expect(page).to have_current_path(client_messages_path(client_id: myclient_id))
      end
    end

  end
end

feature 'User sees client notes on messages page', :js do
  let(:notes) { 'Example text that is more than forty characters long.' }
  let(:truncated_notes) { 'Example text that is more than forty...' }
  let(:myuser) { create :user }
  let(:myclient) { create :client, user: myuser, notes: notes }

  context "visits clients page on mobile" do
    before do
      resize_window_to_mobile
    end

    after do
      resize_window_default
    end

    it 'hides notes on mobile' do
      login_as(myuser, :scope => :user)
      visit client_messages_path(myclient)
      expect(page).to_not have_content truncated_notes
    end
  end

  context 'visits clients page on desktop' do
    before do
      resize_window_default
    end

    it 'shows notes on desktop' do
      login_as(myuser, :scope => :user)
      visit client_messages_path(myclient)
      expect(page).to have_content truncated_notes
    end
  end

  context 'user clicks show more link' do
    let!(:myuser) { create :user }

    let!(:client_with_long_note) { create :client, user: myuser, notes: '12345678901234567890123456789011234567890123456789012345678901' }
    before do
      login_as(myuser, :scope => :user)
      visit client_messages_path(client_with_long_note)
    end

    it 'has show more button' do
      expect(page).to have_content 'More'

    end

    it 'shows full note when show more button is clicked' do
      expect(page).to have_selector('#truncated_note', visible: true)
      expect(page).to have_selector('#full_note', visible: false)

      click_link 'More'

      expect(page).to have_selector('#truncated_note', visible: false)
      expect(page).to have_selector('#full_note', visible: true)

      click_link 'Less'

      expect(page).to have_selector('#truncated_note', visible: true)
      expect(page).to have_selector('#full_note', visible: false)
    end

  end
end
