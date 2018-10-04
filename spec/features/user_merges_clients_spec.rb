require 'rails_helper'

feature 'User merges clients', :js do
  let(:user_mine) { create :user, full_name: 'Debra Terrones' }
  let(:phone_number_from) { '+14155555550' }
  let(:phone_number_from_display) { '(415) 555-5550' }
  let(:phone_number_other) { '+14155555551' }
  let(:phone_number_other_display) { '(415) 555-5551' }
  let(:phone_number_to) { '+14155555552' }
  let(:phone_number_to_display) { '(415) 555-5552' }
  let(:first_name_from) { 'Feaven X.' }
  let(:first_name_other) { 'F.' }
  let(:first_name_to) { 'Feaven' }
  let(:last_name_from) { 'Girma' }
  let(:last_name_other) { 'G.' }
  let(:last_name_to) { 'Girma' }
  let!(:client_to) { create :client, user: user_mine, phone_number: phone_number_to, first_name: first_name_to, last_name: last_name_to }
  let(:rr_to) { ReportingRelationship.find_by(user: user_mine, client: client_to) }

  before do
    FeatureFlag.create!(flag: 'court_dates', enabled: true)
    login_as user_mine, scope: :user
    visit root_path
  end

  context 'the user only has one client' do
    scenario 'the merge form does not appear' do
      within "tr#client_#{client_to.id}" do
        find('td.next-court-date-at', text: '--').click
      end

      expect(page).to have_current_path(edit_client_path(client_to))
      expect(page).to_not have_content('Merge duplicate clients')
    end
  end

  context 'the user has more than one client' do
    let!(:client_other) { create :client, user: user_mine, phone_number: phone_number_other, first_name: first_name_other, last_name: last_name_other }
    let!(:client_from) { create :client, user: user_mine, phone_number: phone_number_from, first_name: first_name_from, last_name: last_name_from }
    let(:rr_other) { ReportingRelationship.find_by(user: user_mine, client: client_other) }
    let(:rr_from) { ReportingRelationship.find_by(user: user_mine, client: client_from) }
    let(:message_body_to) { 'This is a message on the to realtionship' }
    let(:message_body_from) { 'This is a message on the from realtionship' }

    before do
      create_list :text_message, 5, reporting_relationship: rr_to
      create_list :text_message, 5, reporting_relationship: rr_from
      rr_other.update!(last_contacted_at: Time.zone.now)
      rr_to.update!(last_contacted_at: Time.zone.now - 1.day)
      rr_from.update!(last_contacted_at: Time.zone.now - 2.days)
      rr_to.messages.first.update!(body: message_body_to)
      rr_from.messages.first.update!(body: message_body_from)
    end

    scenario 'successfully merges two clients' do
      step 'navigates to "to" client edit form' do
        within "tr#client_#{client_to.id}" do
          find('td.next-court-date-at', text: '--').click
        end

        expect(page).to have_current_path(edit_client_path(client_to))
        expect(page).to have_content('Merge duplicate clients')
        expect(page).to_not have_content('Choose a name')
        expect(page).to_not have_content('Choose a phone number')
      end

      step 'selects "other" client' do
        find('#merge_reporting_relationship_selected_client_id').find(:option, client_other.full_name).select_option
        expect(page).to have_content('Choose a name')
        expect(page).to have_content(client_to.full_name)
        expect(page).to have_content(client_other.full_name)
        expect(page).to have_content('Choose a phone number')
        expect(page).to have_content(phone_number_to_display)
        expect(page).to have_content(phone_number_other_display)
        expect(page).to have_css '#merge_phone_numbers label:nth-child(2) span.label', text: 'NEW'
        expect(page).to have_button('Merge', disabled: true)
      end

      step 'chooses preferred phone number and name' do
        choose client_other.full_name
        choose phone_number_to_display
        expect(page).to have_button('Merge', disabled: false)
      end

      step 'changes mind and selects "from" client' do
        find('#merge_reporting_relationship_selected_client_id').find(:option, client_from.full_name).select_option
        expect(page).to have_content('Choose a name')
        expect(page).to have_content(client_to.full_name)
        expect(page).to have_content(client_from.full_name)
        expect(page).to have_content('Choose a phone number')
        expect(page).to have_content(phone_number_to_display)
        expect(page).to have_content(phone_number_from_display)
        expect(page).to_not have_css '#merge_phone_numbers label:nth-child(2) span.label'
        expect(page).to have_css '#merge_phone_numbers label:nth-child(1) span.label', text: 'NEW'
        expect(page).to have_button('Merge', disabled: true)
      end

      step 'chooses preferred phone number and name and submits the form' do
        choose client_from.full_name
        choose phone_number_to_display
        expect(page).to have_button('Merge', disabled: false)
      end

      step 'submits the merge form' do
        click_on 'Merge'
        expect(page).to have_current_path(reporting_relationship_path(rr_to))
        expect(page).to have_content client_from.full_name
        expect(page).to have_css '.message--content', text: message_body_from
        expect(page).to have_css '.message--content', text: message_body_to
        expect(page).to have_content "\"#{client_from.full_name} #{phone_number_from_display}\" conversation ends"
        expect(page).to have_content "\"#{client_from.full_name} #{phone_number_from_display}\" merged with \"#{client_to.full_name} #{phone_number_to_display}\""
        expect(page).to have_css '.flash__message', text: I18n.t('flash.notices.merge')
      end

      step 'navigates to the client list' do
        click_on 'Home'
        expect(page).to have_current_path(clients_path)
        expect(page).to have_css '.data-table td', text: client_to.reload.full_name
        expect(page).to have_css '.data-table td', text: client_other.reload.full_name
        expect(page).to_not have_css '.data-table td', text: "#{first_name_to} #{last_name_to}"
      end
    end
  end
end
