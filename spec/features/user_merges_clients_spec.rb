require 'rails_helper'

feature 'User merges clients', :js do
  let(:user_mine) { create :user, full_name: 'Debra Terrones' }
  let(:phone_number_source) { '+14155555550' }
  let(:phone_number_source_display) { '(415) 555-5550' }
  let(:phone_number_target) { '+14155555551' }
  let(:phone_number_target_display) { '(415) 555-5551' }
  let(:first_name_source) { 'Feaven' }
  let(:first_name_target) { 'Feaven X.' }
  let(:last_name_source) { 'Girma' }
  let(:last_name_target) { 'Girma' }
  let!(:client_target) { create :client, user: user_mine, phone_number: phone_number_target, first_name: first_name_target, last_name: last_name_target }

  before do
    FeatureFlag.create!(flag: 'court_dates', enabled: true)
    login_as user_mine, scope: :user
    visit root_path
  end

  context 'the user only has one client' do
    scenario 'the merge form does not appear' do
      within "tr#client_#{client_target.id}" do
        find('td.next-court-date-at', text: '--').click
      end

      expect(page).to have_current_path(edit_client_path(client_target))
      expect(page).to_not have_content('Merge duplicate clients')
    end
  end

  context 'the user has more than one client' do
    let!(:client_source) { create :client, user: user_mine, phone_number: phone_number_source, first_name: first_name_source, last_name: last_name_source }

    scenario 'successfully merges two clients' do
      step 'navigates to target client edit form' do
        within "tr#client_#{client_target.id}" do
          find('td.next-court-date-at', text: '--').click
        end

        expect(page).to have_current_path(edit_client_path(client_target))
        expect(page).to have_content('Merge duplicate clients')
        expect(page).to_not have_content('Choose a name')
        expect(page).to_not have_content('Choose a phone number')
        expect(page).to_not have_content(phone_number_target_display)
      end

      step 'selects source client' do
        find('#reporting_relationship_client_id').find(:option, client_source.full_name).select_option
        expect(page).to have_content('Choose a name')
        expect(page).to have_content('Choose a phone number')
        expect(page).to have_content(phone_number_target_display)
      end
    end
  end

  context 'Another user has relationships with the clients' do
    let!(:user_other) { create :user, full_name: 'Joshua Nelson' }
  end
end
