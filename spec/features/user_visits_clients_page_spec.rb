require 'rails_helper'

feature 'clients have categories' do
  let(:department) { create :department }
  let(:user) { create :user, department: department }

  before do
    login_as user
  end

  describe 'setting and sorting categories', js: true do
    let!(:rr1) { create :reporting_relationship, user: user, client: create(:client) }
    let!(:rr2) { create :reporting_relationship, user: user, client: create(:client) }
    let!(:rr3) { create :reporting_relationship, user: user, client: create(:client) }
    let!(:rr4) { create :reporting_relationship, user: user, client: create(:client) }

    before do
      rr1.update(category: 'yellow_star')
      rr2.update(category: 'green_star')
      rr3.update(category: 'empty_star')
      rr4.update(category: 'red_star')
    end

    scenario 'user sees list of clients with categories' do
      step 'user loads client list' do
        visit clients_path

        expect(page).to have_css('tr:first-child', text: rr4.client.full_name)
        expect(page).to have_css('tr:nth-child(2)', text: rr3.client.full_name)
        expect(page).to have_css('tr:nth-child(3)', text: rr2.client.full_name)
        expect(page).to have_css('tr:last-child', text: rr1.client.full_name)
      end

      step 'user sorts clients by category' do
        find('th:first-child').click

        expect(page).to have_css('tr:first-child', text: rr2.client.full_name)
        expect(page).to have_css('tr:nth-child(2)', text: rr1.client.full_name)
        expect(page).to have_css('tr:nth-child(3)', text: rr4.client.full_name)
        expect(page).to have_css('tr:last-child', text: rr3.client.full_name)
      end

      step 'user selects red category on first client' do
        within 'tr:first-child', text: rr2.client.full_name do
          find('td.category-order').click.click

          expect(page).to have_css('i.icon-star-red')
        end
      end

      step 'user resorts the list' do
        find('th:first-child').click

        expect(page).to have_css('tr:first-child', text: rr1.client.full_name)
        expect(page).to have_css('tr:nth-child(2)', text: rr4.client.full_name)
        expect(page).to have_css('tr:nth-child(3)', text: rr2.client.full_name)
        expect(page).to have_css('tr:last-child', text: rr3.client.full_name)
      end
    end
  end
end

feature 'logged-out user visits clients page' do
  scenario 'and is redirected to the login form' do
    visit clients_path
    expect(page).to have_text 'Log in'
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'manage action is hidden on mobile', js: true do
  scenario 'user visits client list on mobile' do
    myuser = create :user
    create :client, user: myuser
    login_as(myuser, :scope => :user)

    visit clients_path
    resize_window_to_mobile
    expect(page).to_not have_text 'Manage'
    expect(page).to_not have_text 'Action'
    resize_window_to_default
  end
end

feature 'logged-in user visits clients page' do
  scenario 'successfully' do
    myuser = create :user
    login(myuser)
  end
end
