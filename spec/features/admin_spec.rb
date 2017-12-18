require 'rails_helper'

feature 'Admin Panel' do
  let(:admin_user) { create :admin_user }

  before do
    login_as(admin_user, :scope => :admin_user)
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

  describe 'Client Edit' do
    let(:transfer_note) { 'Welcome your new client.' }
    let!(:department1) { create :department, name: 'Department One' }
    let!(:department2) { create :department, name: 'Department Two' }
    let!(:user1) { create :user, department: department1 }
    let!(:user2) { create :user, department: department1 }
    let!(:user3) { create :user, department: department2 }
    let!(:client1) { create :client, users: [user1] }

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
        expect(page).to have_content('ADMIN / CLIENTS /')
        expect(page).to have_content('Change user')
        expect(page).to have_select("user_in_dept_#{department2.id}", options: ['', user3.full_name])
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
        expect(page).to have_content("ADMIN / CLIENTS / #{client1.full_name.upcase}")
        expect(page).to have_content('Change user')
        expect(page).to have_select("user_in_dept_#{department1.id}", options: ['', user1.full_name, user2.full_name])
        expect(page).to have_content('Include a message for the new user')
      end

      step 'it completes the form and submits it' do
        select user2.full_name, from: 'Transfer to'
        fill_in 'transfer_note', with: 'Notes notes notes.'

        click_on 'Transfer Client'

        expect(page).to have_content("#{client1.full_name} has been assigned to #{user2.full_name} in #{department1.name}")
        expect(page.current_path).to eq(admin_client_path(client1))
      end
    end
  end
end
