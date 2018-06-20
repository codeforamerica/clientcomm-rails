require 'rails_helper'

feature 'Admin Panel' do
  let(:admin_user) { create :admin_user }

  before do
    login_as(admin_user, scope: :admin_user)
  end

  describe 'User View' do
    let!(:user1) { create :user }
    let!(:user2) { create :user }
    let!(:client1) { create :client, users: [user1] }
    let!(:client2) { create :client, users: [user1] }
    let!(:client3) { create :client, users: [user2] }
    let!(:client4) { create :client, users: [user2] }

    scenario 'Admin wants to view clients for a user' do
      visit admin_user_path(user1)

      within '#main_content' do
        click_on 'Clients'
      end

      expect(page).to have_content(client1.full_name)
      expect(page).to have_content(client2.full_name)
      expect(page).to_not have_content(client3.full_name)
      expect(page).to_not have_content(client4.full_name)
    end
  end

  describe 'User Edit' do
    let(:department_from) { create :department }
    let(:department_to) { create :department }
    let(:user_no_clients) { create :user, department: department_from, full_name: 'Gabriel Robel' }
    let!(:user_inactive_client) { create :user, department: department_from, full_name: 'Nile Hagos' }
    let!(:user_active_client) { create :user, department: department_from, full_name: 'Kinfe Fikru' }
    let!(:user_other_department) { create :user, department: department_to, full_name: 'Nebay Mehari' }
    let!(:client1) { create :client, user: user_inactive_client, first_name: 'Simret', last_name: 'Abaalom' }
    let!(:client2) { create :client, user: user_active_client, first_name: 'Abraham', last_name: 'Haylom' }

    before do
      ReportingRelationship.create(client: client1, user: user_other_department, active: false)
      ReportingRelationship.create(client: client2, user: user_other_department, active: true)
    end

    scenario 'Changing user departments' do
      step 'visits the view page for a user with no clients that have relationships in another department' do
        visit admin_user_path(user_no_clients)

        expect(page).to have_content(user_no_clients.full_name)
        expect(page).to have_content(department_from.name)
        expect(page).to_not have_content(department_to.name)
      end

      step 'edits the user' do
        click_on 'Edit User'

        expect(page.current_path).to eq(edit_admin_user_path(user_no_clients))
        expect(page).to have_content(user_no_clients.full_name)
        expect(page).to have_content('Edit User')
        expect(page).to have_select(
          'Department',
          options: [department_from.name, department_to.name],
          selected: department_from.name
        )
      end

      step 'selects a new department and submits the form' do
        select department_to.name, from: 'Department'
        click_on 'Update User'

        expect(page.current_path).to eq(admin_user_path(user_no_clients))
        expect(page).to have_content('User was successfully updated.')
        expect(page).to have_content(department_to.name)
        expect(page).to_not have_content(department_from.name)
      end

      step 'visits the view page for a user with a client with an inactive relationship in another department' do
        visit edit_admin_user_path(user_inactive_client)

        expect(page).to have_content(user_inactive_client.full_name)
        expect(page).to have_content('Edit User')
        expect(page).to have_select(
          'Department',
          options: [department_from.name, department_to.name],
          selected: department_from.name
        )
      end

      step 'selects a new department and submits the form' do
        select department_to.name, from: 'Department'
        click_on 'Update User'

        expect(page.current_path).to eq(admin_user_path(user_inactive_client))
        expect(page).to have_content('User was successfully updated.')
        expect(page).to have_content(department_to.name)
        expect(page).to_not have_content(department_from.name)
      end

      step 'visits the view page for a user with a client with an active relationship in another department' do
        visit edit_admin_user_path(user_active_client)

        expect(page).to have_content(user_active_client.full_name)
        expect(page).to have_content('Edit User')
        expect(page).to have_select(
          'Department',
          options: [department_from.name, department_to.name],
          selected: department_from.name
        )
      end

      step 'selects a new department and submits the form' do
        select department_to.name, from: 'Department'
        click_on 'Update User'
        expect(page.current_path).to eq(admin_user_path(user_active_client))
        error_message = I18n.t('activerecord.errors.models.user.attributes.reporting_relationships.invalid')
        expect(page).to have_content(error_message)
      end
    end
  end

  describe 'Client Index' do
    let(:department1) { create :department }
    let(:department2) { create :department }
    let!(:user1) { create :user, department: department1 }
    let!(:user2) { create :user, department: department2 }
    let!(:user3) { create :user, department: department1, active: false }
    let!(:user4) { create :user, department: department2, active: false }
    let!(:client1) { create :client, user: user1 }
    let!(:client2) { create :client, user: user2 }
    let!(:client3) { create :client, user: user3 }
    let!(:client4) { create :client, user: user4 }

    context 'filtering by department' do
      it 'shows all clients when not filtered' do
        visit admin_client_relationships_path

        expect(page).to have_content(client1.full_name)
        expect(page).to have_content(client2.full_name)
        expect(page).to have_content(client3.full_name)
        expect(page).to have_content(client4.full_name)
      end

      it 'shows clients with active users in the selected department' do
        visit admin_client_relationships_path

        select department1.name, from: 'Department'

        click_on 'Filter'

        expect(page).to have_content(client1.full_name)
        expect(page).to_not have_content(client2.full_name)
        expect(page).to have_content(client3.full_name)
        expect(page).to_not have_content(client4.full_name)
      end
    end
  end

  describe 'Client View' do
    let!(:department1) { create :department, name: 'Department One' }
    let!(:user1) { create :user, department: department1 }
    let(:phone_number) { '+14155551212' }
    let!(:client1) { create :client, users: [user1], phone_number: phone_number }

    context 'client id number and court date feature flags are enabled' do
      before do
        FeatureFlag.create!(flag: 'client_id_number', enabled: true)
        FeatureFlag.create!(flag: 'court_dates', enabled: true)
      end

      it 'shows fields for enabled feature flags' do
        visit admin_client_path(client1)
        expect(page).to have_css '.row-next_court_date_at', text: 'Next Court Date At'
        expect(page).to have_css '.row-id_number', text: 'Id Number'
      end
    end

    context 'client id number and court date feature flags are disabled' do
      before do
        FeatureFlag.create!(flag: 'client_id_number', enabled: false)
        FeatureFlag.create!(flag: 'court_dates', enabled: false)
      end

      it 'does not show fields for disabled feature flags' do
        visit admin_client_path(client1)
        expect(page).to_not have_css '.row-next_court_date_at', text: 'Next Court Date At'
        expect(page).to_not have_css '.row-id_number', text: 'Id Number'
      end
    end
  end

  describe 'Client Edit' do
    let(:transfer_note) { 'Welcome your new client.' }
    let!(:department1) { create :department, name: 'Department One' }
    let!(:department2) { create :department, name: 'Department Two' }
    let!(:user1) { create :user, department: department1 }
    let!(:user2) { create :user, department: department1 }
    let!(:user3) { create :user, department: department2 }
    let(:phone_number) { '+14155551212' }
    let(:new_phone_number) { '+14155551213' }
    let(:new_phone_number_display) { '(415) 555-1213' }
    let!(:client1) { create :client, users: [user1], phone_number: phone_number }

    scenario 'assigning a client to a user' do
      step 'visits the edit client page' do
        visit edit_admin_client_path(client1)

        expect(page).to have_content(department1.name.capitalize)
        expect(page).to have_content(user1.full_name)
        expect(page).to have_content(department2.name.capitalize)
        expect(page).to have_content('Assign user')
      end

      step 'clicks the assign user link next to a user' do
        click_on('Assign user')

        expect(page).to have_content('Transfer Client')
        expect(page).to have_content('Change user')
        expect(page).to have_select("user_in_dept_#{department2.id}", options: ['', user3.full_name, department2.unclaimed_user.full_name])
        expect(page).to have_content('Include a message for the new user')
      end

      step 'it completes the form and submits it' do
        select user3.full_name, from: 'Transfer to'
        fill_in 'transfer_note', with: transfer_note

        click_on 'Transfer Client'

        expect(page).to have_content("#{client1.full_name} has been assigned to #{user3.full_name} in #{department2.name}")
        expect(page.current_path).to eq(admin_client_path(client1))

        emails = ActionMailer::Base.deliveries
        expect(emails.count).to eq 1
        expect(emails.first.html_part.to_s).to include transfer_note
        expect(emails.first.html_part.to_s).to include 'An administrator has transferred'
      end
    end

    context 'shared client' do
      before do
        ReportingRelationship.create(client: client1, user: user3)
      end

      scenario 'editing a client profile' do
        step 'visits the edit_page' do
          visit edit_admin_client_path(client1)
          expect(find_field('Phone number').value).to eq(phone_number)
        end

        step 'enters new phone number and submits form' do
          fill_in 'Phone number', with: new_phone_number
          click_on 'Update Client'
          expect(page).to have_content('Client was successfully updated.')
          expect(page).to have_css '.row-phone_number', text: new_phone_number
        end

        step 'logs out and logs in as one of the client users' do
          logout(admin_user)
          login_as(user1, scope: :user)
          visit root_path
        end

        step 'loads the conversation page' do
          click_on client1.full_name
          user1_rr = user1.reporting_relationships.find_by(client: client1)
          expect(page).to have_current_path(reporting_relationship_path(user1_rr))
          expect(page).to have_css '.message--event', text:
            I18n.t(
              'messages.phone_number_edited',
              user_full_name: I18n.t('messages.admin_user_description'),
              new_phone_number: new_phone_number_display
            )
        end

        step 'logs out and logs in as the other client user' do
          logout(user1)
          login_as(user3, scope: :user)
          visit root_path
        end

        step 'loads the conversation page' do
          click_on client1.full_name
          user3_rr = user3.reporting_relationships.find_by(client: client1)
          expect(page).to have_current_path(reporting_relationship_path(user3_rr))
          expect(page).to have_css '.message--event', text:
            I18n.t(
              'messages.phone_number_edited',
              user_full_name: I18n.t('messages.admin_user_description'),
              new_phone_number: new_phone_number_display
            )
        end
      end
    end

    context 'deactivate links' do
      before do
        ReportingRelationship.create(client: client1, user: user2, active: false)
      end

      scenario 'deactivating and reactivating a relationship to a user' do
        step 'visits the edit page, clicks the deactivate link next to a user' do
          visit edit_admin_client_path(client1)

          expect(page).to have_link('Change')
          click_on('Deactivate')

          expect(page.current_path).to eq(admin_client_path(client1))
          expect(page).to have_content("#{client1.full_name} has been deactivated for #{user1.full_name} in #{department1.name}.")
        end

        step 'visits the edit page, clicks the reactivate link next to a user' do
          visit edit_admin_client_path(client1)
          expect(page).to have_content(user1.full_name)
          expect(page).to_not have_content(user2.full_name)
          expect(page).to have_link('Change')
          click_on('Reactivate')

          expect(page.current_path).to eq(admin_client_path(client1))
          expect(page).to have_content("#{client1.full_name} has been reactivated for #{user1.full_name} in #{department1.name}.")
        end
      end
    end

    scenario 'transferring a client to a new user' do
      step 'visits the edit client page' do
        visit edit_admin_client_path(client1)

        expect(page).to have_content(department1.name.capitalize)
        expect(page).to have_content(user1.full_name)
        expect(page).to have_content(department2.name.capitalize)
        expect(page).to have_content('Assign user')
      end

      step 'clicks the change link next to a user' do
        click_on('Change')

        expect(page).to have_content('Transfer Client')
        expect(page).to have_content('Change user')
        expect(page).to have_select("user_in_dept_#{department1.id}", options: ['', user1.full_name, user2.full_name, department2.unclaimed_user.full_name])
        expect(page).to have_content('Include a message for the new user')
      end

      step 'it completes the form and submits it' do
        select user2.full_name, from: 'Transfer to'
        fill_in 'transfer_note', with: 'Notes notes notes.'

        click_on 'Transfer Client'

        expect(page).to have_content("#{client1.full_name} has been assigned to #{user2.full_name} in #{department1.name}")
        expect(page.current_path).to eq(admin_client_path(client1))
        expect_most_recent_analytics_event(
          'client_transfer' => {
            'clients_transferred_count' => 1,
            'transferred_by' => 'admin',
            'has_transfer_note' => true,
            'unread_messages' => false
          }
        )
      end
    end

    context 'unread messages' do
      let(:rr) { ReportingRelationship.find_by(user: user1, client: client1) }

      scenario 'transferring a client to a new user' do
        step 'visits the edit client page' do
          visit edit_admin_client_path(client1)

          expect(page).to have_content(department1.name.capitalize)
          expect(page).to have_content(user1.full_name)
          expect(page).to have_content(department2.name.capitalize)
          expect(page).to have_content('Assign user')
        end

        step 'clicks the change link next to a user' do
          click_on('Change')

          expect(page).to have_content('Transfer Client')
          expect(page).to have_content('Change user')
          expect(page).to have_select("user_in_dept_#{department1.id}", options: ['', user1.full_name, user2.full_name, department1.unclaimed_user.full_name])
          expect(page).to have_content('Include a message for the new user')
        end

        step 'a new message has come in and an error is shown' do
          msg = create :text_message, reporting_relationship: rr, read: false
          rr.update!(has_unread_messages: true)

          select user2.full_name, from: 'Transfer to'
          fill_in 'transfer_note', with: 'Notes notes notes.'

          click_on 'Transfer Client'

          expect(page).to have_content('Transfer Client and Mark Messages As Read')
          expect(page).to have_content('Change user')
          expect(page).to have_select("user_in_dept_#{department1.id}", options: ['', user1.full_name, user2.full_name, department1.unclaimed_user.full_name])
          expect(page).to have_content('Include a message for the new user')

          expect(page).to have_content('This client has unread messages. The messages will not be transferred to the new user.')

          select user2.full_name, from: 'Transfer to'
          fill_in 'transfer_note', with: 'Notes notes notes.'

          click_on 'Transfer Client and Mark Messages As Read'

          expect(msg.reload).to be_read
          expect(rr.reload.has_unread_messages).to eq(false)

          expect(page).to have_content("#{client1.full_name} has been assigned to #{user2.full_name} in #{department1.name}")
          expect(page.current_path).to eq(admin_client_path(client1))
          expect_most_recent_analytics_event(
            'client_transfer' => {
              'clients_transferred_count' => 1,
              'transferred_by' => 'admin',
              'has_transfer_note' => true,
              'unread_messages' => true
            }
          )
        end
      end
    end

    context 'client id number feature flag is enabled' do
      let(:id_number) { '1234567' }

      before do
        FeatureFlag.create!(flag: 'client_id_number', enabled: true)
      end

      it 'allows client id number field to be filled out and submitted' do
        visit edit_admin_client_path(client1)

        expect(page).to have_css '#client_id_number_input', text: 'Id number'
        fill_in 'Id number', with: id_number
        click_on 'Update Client'
        expect(page).to have_content('Client was successfully updated.')
        expect(page).to have_css '.row-id_number', text: id_number
      end
    end

    context 'court date feature flag is enabled' do
      let(:year) { 2018 }
      let(:month) { 'July' }
      let(:day) { 21 }

      before do
        FeatureFlag.create!(flag: 'court_dates', enabled: true)
      end

      it 'allows court date field to be filled out and submitted' do
        visit edit_admin_client_path(client1)

        expect(page).to have_select('client[next_court_date_at(1i)]')
        expect(page).to have_select('client[next_court_date_at(2i)]')
        expect(page).to have_select('client[next_court_date_at(3i)]')

        select year, from: 'client[next_court_date_at(1i)]'
        select month, from: 'client[next_court_date_at(2i)]'
        select day, from: 'client[next_court_date_at(3i)]'

        click_on 'Update Client'

        expect(page).to have_content('Client was successfully updated.')
        expect(page).to have_css '.row-next_court_date_at', text: "#{month} #{day}, #{year}"
      end
    end
  end

  describe 'Court Reminder CSV Download' do
    let(:filename) { 'court_dates.csv' }
    let(:court_dates_path) { Rails.root.join('spec', 'fixtures', filename) }
    let!(:court_date_csv) { CourtDateCSV.create(file: File.new(court_dates_path), admin_user: admin_user) }

    scenario 'Admin wants to download a court reminder CSV file' do
      step 'visits court reminder csv index' do
        visit admin_court_date_csvs_path
        expect(page).to have_css('td.col-file_file_name'), text: filename
      end

      step 'visits show page' do
        click_on 'View'
        expect(page).to have_current_path admin_court_date_csv_path(court_date_csv)
      end

      step 'downloads csv file' do
        click_on filename
        expect(page).to have_current_path download_admin_court_date_csv_path(court_date_csv)
        expect(page.response_headers['Content-Type']).to eq 'text/csv'
      end
    end
  end
end
