require 'rails_helper'

feature 'User clicks on client in list', :js do
  describe 'and sees the messages page' do
    let!(:myuser) { create :user }
    let!(:myclient) { create :client, user: myuser }
    let(:rr) { ReportingRelationship.find_by(user: myuser, client: myclient) }

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
        expect(page).to have_current_path(reporting_relationship_path(rr))
      end
    end

    context 'on the messages page' do
      before do
        login_as(myuser, :scope => :user)
        visit reporting_relationship_path(rr)
      end

      it 'shows the client name in the header' do
        expect(page).to have_content myclient.full_name
      end

      it 'shows the client phone number in the header' do
        expect(page).to have_content PhoneNumberParser.format_for_display(myclient.phone_number)
      end

      # get the id from the saved client record
      it 'has the correct path for the client' do
        rr = myuser.reporting_relationships.find_by(client: myclient)
        expect(page).to have_current_path(reporting_relationship_path(rr))
      end

      context 'sorting' do
        let(:rr) { ReportingRelationship.find_by(user: myuser, client: myclient) }
        let(:messageone) { build :message, reporting_relationship: rr }
        let(:messagetwo) { build :message, reporting_relationship: rr }

        before do
          today = Time.now

          travel_to 2.days.ago do
            messageone.send_at = today
            messageone.save
          end

          travel_to 1.day.ago do
            messagetwo.send_at = Time.now
            messagetwo.save
          end

          rr = myuser.reporting_relationships.find_by(client: myclient)
          visit reporting_relationship_path(rr)
        end

        it 'sorts messages by send_at' do
          expect(page).to have_content(/#{messagetwo.body}.*#{messageone.body}/)
        end
      end
    end
  end
end

feature 'User sees client notes on messages page', :js do
  let(:notes) { 'Example text that is more than forty characters long.' }
  let(:truncated_notes) { 'Example text that is more than forty...' }
  let(:myuser) { create :user }
  let(:myclient) { create :client }
  let!(:rr) { ReportingRelationship.create(client: myclient, user: myuser, notes: notes) }

  context 'visits clients page on mobile' do
    before do
      resize_window_to_mobile
    end

    after do
      resize_window_to_default
    end

    it 'hides notes on mobile' do
      login_as(myuser, :scope => :user)
      visit reporting_relationship_path(rr)
      expect(page).to_not have_content truncated_notes
    end
  end

  context 'visits clients page on desktop' do
    before do
      resize_window_to_default
    end

    it 'shows notes on desktop' do
      login_as(myuser, :scope => :user)
      visit reporting_relationship_path(rr)
      expect(page).to have_content truncated_notes
    end
  end

  context 'user clicks show more link' do
    let(:myuser) { create :user }
    let(:notes) { '12345678901234567890123456789011234567890123456789012345678901' }
    let(:truncated_notes) { '123456789012345678901234567890112345...' }
    let(:client_with_long_note) { create :client }
    let!(:rr) { ReportingRelationship.create(client: client_with_long_note, user: myuser, notes: notes) }

    before do
      login_as(myuser, :scope => :user)
      visit reporting_relationship_path(rr)
    end

    it 'has show more button' do
      expect(page).to have_content 'More'
    end

    it 'shows full note when show more button is clicked' do
      expect(page).to have_selector('#truncated_note', visible: true)
      expect(page).to have_selector('#full_note', visible: false)
      expect(page).to have_content truncated_notes

      click_link 'More'

      expect(page).to have_selector('#truncated_note', visible: false)
      expect(page).to have_selector('#full_note', visible: true)
      expect(page).to have_content notes

      click_link 'Less'

      expect(page).to have_selector('#truncated_note', visible: true)
      expect(page).to have_selector('#full_note', visible: false)
      expect(page).to have_content truncated_notes
    end
  end
end
