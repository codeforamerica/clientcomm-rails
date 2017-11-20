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
    let(:department) { create :department }
    let!(:user1) { create :user, department: department }
    let!(:user2) { create :user, department: department, active: false }
    let!(:client1) { create :client, users: [user1] }

    context 'transferring a client' do
      it 'does not show inactive users' do
        visit edit_admin_client_path(client1)

        expect(page).to have_select("user_in_dept_#{department.id}", options: ['', user1.full_name])
      end
    end
  end
end
