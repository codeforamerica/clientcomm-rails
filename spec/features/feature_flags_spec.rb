require 'rails_helper'

feature 'feature flags' do

  describe 'signups' do
    before do
      @signups_value = ENV['ALLOW_SIGNUPS']
    end

    after do
      ENV['ALLOW_SIGNUPS'] = @signups_values
    end

    context 'disabled' do
      before do
        ENV['ALLOW_SIGNUPS'] = 'false'
      end

      it 'redirects to the login page' do
        visit new_user_registration_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context 'enabled' do
      before do
        ENV['ALLOW_SIGNUPS'] = 'true'
      end

      let(:user_email) { 'some@email.com' }
      let(:user_password) { 'a strong password' }

      it 'allows signups' do
        visit new_user_registration_path

        expect(page).to have_content('Sign up')

        fill_in 'Email', with: user_email
        fill_in 'Password', with: user_password
        fill_in 'Password confirmation', with: user_password

        click_on 'Sign up'

        expect(page).to have_text user_email
        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe 'search and sort' do
    let!(:myuser) { create :user }

    context 'disabled' do
      before do
        ENV['SEARCH_AND_SORT'] = 'false'
        login_as(myuser, :scope => :user)
        visit clients_path
      end

      it 'does not show search input' do
        expect(page).to_not have_css('.searchbar__input')
        expect(page).to_not have_css('.glyphicon-search')
        expect(page).to_not have_css('.glyphicon-remove')
      end

      it 'does not show sort icons' do
        expect(page).to_not have_css('.glyphicon-resize-vertical')
        expect(page).to_not have_css('.glyphicon-arrow-up')
        expect(page).to_not have_css('.glyphicon-arrow-down')
      end

      it 'does not have sort classes ' do
        expect(page).to_not have_css('.sort')
      end

    end

    context 'enabled' do
      before do
        ENV['SEARCH_AND_SORT'] = 'true'
        login_as(myuser, :scope => :user)
        visit clients_path
      end

      it 'shows search input' do
        expect(page).to have_css('.searchbar__input')
        expect(page).to have_css('.glyphicon-search')
        expect(page).to have_css('.glyphicon-remove')
      end

      it 'shows sort icons' do
        expect(page).to have_css('.glyphicon-resize-vertical')
        expect(page).to have_css('.glyphicon-arrow-up')
        expect(page).to have_css('.glyphicon-arrow-down')
      end

      it 'has sort classes ' do
        expect(page).to have_css('.sort')
      end

    end
  end
end
