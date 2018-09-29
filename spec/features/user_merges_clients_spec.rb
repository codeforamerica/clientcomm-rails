require 'rails_helper'

feature 'User merges clients', :js do
  let(:user_mine) { create :user, full_name: 'Debra Terrones' }
  let(:phone_number_source) { '+14155555550' }
  let(:phone_number_source_display) { '(415) 555-5550' }
  let(:phone_number_second) { '+14155555551' }
  let(:phone_number_second_display) { '(415) 555-5551' }
  let(:phone_number_target) { '+14155555552' }
  let(:phone_number_target_display) { '(415) 555-5552' }
  let(:first_name_source) { 'Feaven X.' }
  let(:first_name_second) { 'F.' }
  let(:first_name_target) { 'Feaven' }
  let(:last_name_source) { 'Girma' }
  let(:last_name_second) { 'G.' }
  let(:last_name_target) { 'Girma' }
  let!(:client_target) { create :client, user: user_mine, phone_number: phone_number_target, first_name: first_name_target, last_name: last_name_target }
  let(:rr_target) { ReportingRelationship.find_by(user: user_mine, client: client_target) }

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
    let!(:client_second) { create :client, user: user_mine, phone_number: phone_number_second, first_name: first_name_second, last_name: last_name_second }
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
      end

      step 'selects second client' do
        find('#merge_reporting_relationship_selected_client_id').find(:option, client_second.full_name).select_option
        expect(page).to have_content('Choose a name')
        expect(page).to have_content(client_target.full_name)
        expect(page).to have_content(client_second.full_name)
        expect(page).to have_content('Choose a phone number')
        expect(page).to have_content(phone_number_target_display)
        expect(page).to have_content(phone_number_second_display)
        expect(page).to have_button('Merge', disabled: true)
      end

      step 'chooses preferred phone number and name' do
        choose client_second.full_name
        choose phone_number_target_display
        expect(page).to have_button('Merge', disabled: false)
      end

      step 'changes mind and selects source client' do
        find('#merge_reporting_relationship_selected_client_id').find(:option, client_source.full_name).select_option
        expect(page).to have_content('Choose a name')
        expect(page).to have_content(client_target.full_name)
        expect(page).to have_content(client_source.full_name)
        expect(page).to have_content('Choose a phone number')
        expect(page).to have_content(phone_number_target_display)
        expect(page).to have_content(phone_number_source_display)
        expect(page).to have_button('Merge', disabled: true)
      end

      step 'chooses preferred phone number and name and submits the form' do
        choose client_source.full_name
        choose phone_number_target_display
        expect(page).to have_button('Merge', disabled: false)
      end

      step 'submits the merge form' do
        click_on 'Merge'
        expect(page).to have_current_path(reporting_relationship_path(rr_target))
        expect(page).to have_content client_source.full_name
        expect(page).to have_content "\"#{client_source.full_name} #{phone_number_source_display}\" conversation ends"
        expect(page).to have_content "\"#{client_source.full_name} #{phone_number_source_display}\" merged with \"#{client_target.full_name} #{phone_number_target_display}\""
        expect(page).to have_css '.flash__message', text: I18n.t('flash.notices.merge')
      end
    end
  end

  context 'Another user has relationships with the clients' do
    let!(:user_other) { create :user, full_name: 'Joshua Nelson' }
  end
end
