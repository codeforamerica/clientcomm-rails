require 'rails_helper'

feature 'creating and editing departments' do
  let(:department_name) { 'Main' }
  let(:department_phone_number) { '+14155551212' }
  let(:user_full_name) { 'Jenny Smith' }
  let(:user_email) { 'jenny@example.com' }
  let(:user_password) { 'password' }
  let(:admin_user) { create :admin_user }

  scenario 'admin user creates and edits a department' do
    step 'when user logs in' do
      login_as(admin_user, scope: :admin_user)
    end

    step 'when user visits the departments page' do
      visit admin_departments_path
      expect(page.find('#page_title')).to have_content('Departments')
    end

    step 'when user clicks on new department button' do
      click_on 'New Department'
      expect(page.find('#page_title')).to have_content('New Department')
    end

    step 'when user fills in and submits the new department form' do
      fill_in 'Name', with: department_name
      fill_in 'Phone number', with: department_phone_number
      click_on 'Create Department'
      expect(page).to have_content('Department was successfully created.')
    end

    step 'when user creates a new user in the department' do
      click_on 'Users'
      expect(page.find('#page_title')).to have_content('Users')
      click_on 'New User'
      expect(page.find('#page_title')).to have_content('New User')
      fill_in 'Full name', with: user_full_name
      fill_in 'Email', with: user_email
      fill_in 'Password*', with: user_password, exact: true
      fill_in 'Password confirmation', with: user_password, exact: true
      select department_name, from: 'Department'
      click_on 'Create User'
      expect(page).to have_content('User was successfully created.')
    end

    step 'when user clicks on edit department button' do
      visit admin_departments_path
      click_on 'Edit'
      expect(page.find('#page_title')).to have_content('Edit Department')
    end

    step 'when user selects an unclaimed user for the department' do
      select user_full_name, from: 'User'
      click_on 'Update Department'
      expect(page).to have_content('Department was successfully updated.')
      expect(page.find('.row-unclaimed_user')).to have_content(user_full_name)
    end

    step 'when user tries to delete the department' do
      click_on 'Delete Department'
      expect(page).to have_content('Cannot delete a department with active users.')
    end

    step 'when user disables the only user for the department' do
      click_on 'Users'
      expect(page.find('#page_title')).to have_content('Users')
      click_on 'Disable'
      click_on 'Disable account'
    end

    step 'when user deletes the department' do
      click_on 'Departments'
      click_link 'Delete'
      expect(page).to have_content('Department was successfully destroyed.')
    end
  end
end
