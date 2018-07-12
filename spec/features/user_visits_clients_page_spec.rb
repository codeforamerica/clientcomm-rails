require 'rails_helper'

feature 'clients have categories' do
  let(:department) { create :department }
  let(:user) { create :user, department: department }

  before do
    FeatureFlag.create!(flag: 'categories', enabled: true)
    login_as user
  end

  describe 'setting and sorting categories', js: true do
    let!(:rr1) { create :reporting_relationship, user: user, client: create(:client), created_at: Time.zone.now - 4.minutes, updated_at: Time.zone.now - 4.minutes }
    let!(:rr2) { create :reporting_relationship, user: user, client: create(:client), created_at: Time.zone.now - 3.minutes, updated_at: Time.zone.now - 3.minutes }
    let!(:rr3) { create :reporting_relationship, user: user, client: create(:client), created_at: Time.zone.now - 2.minutes, updated_at: Time.zone.now - 2.minutes }
    let!(:rr4) { create :reporting_relationship, user: user, client: create(:client), created_at: Time.zone.now - 1.minute, updated_at: Time.zone.now - 1.minute }

    before do
      rr1.update(category: 'cat2')
      rr2.update(category: 'cat1')
      rr3.update(category: 'no_cat')
      rr4.update(category: 'cat3')
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

          expect(page).to have_css('i.icon-icon3')
        end

        within 'tr:nth-child(3)', text: rr4.client.full_name do
          find('td.category-order').click.click

          expect(page).to have_css('i.icon-icon1')
        end
      end

      step 'user resorts the list' do
        find('th:first-child').click.click

        expect(page).to have_css('tr:first-child', text: rr4.client.full_name)
        expect(page).to have_css('tr:nth-child(2)', text: rr1.client.full_name)
        expect(page).to have_css('tr:nth-child(3)', text: rr2.client.full_name)
        expect(page).to have_css('tr:last-child', text: rr3.client.full_name)
      end

      step 'when the page is reloaded' do
        sleep 2
        wait_for_ajax

        visit clients_path

        within 'tr', text: rr2.client.full_name do
          expect(page).to have_css('i.icon-icon3')
        end

        within 'tr', text: rr4.client.full_name do
          expect(page).to have_css('i.icon-icon1')
        end
      end

      step 'when a text is received' do
        find('th:first-child').click
        expect(page).to have_css('tr:last-child', text: rr3.client.full_name)

        twilio_post_sms(
          twilio_new_message_params(
            to_number: department.phone_number,
            from_number: rr3.client.phone_number,
            msg_txt: 'irelevant'
          )
        )

        expect(page).to have_css('tr:first-child', text: rr3.client.full_name)

        within 'tr:first-child', text: rr3.client.full_name do
          find('td.category-order').click.click

          expect(page).to have_css('i.icon-icon2')
        end
      end

      step 'the reloaded page shows correct categories' do
        sleep 2
        visit clients_path

        within 'tr', text: rr3.client.full_name do
          expect(page).to have_css('i.icon-icon2')
        end
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
    login_as(myuser, scope: :user)

    visit clients_path
    resize_window_to_mobile
    expect(page).to_not have_text 'Manage'
    expect(page).to_not have_text 'Action'
    resize_window_to_default
  end
end

feature 'logged-in user interacts with texts of change' do
  let(:department) { create :department }
  let(:user) { create :user, department: department }
  let!(:clients) { create_list :client, 5, user: user }
  let(:admin_user) { create :admin_user }
  let(:filename) { 'fluffy_cat.jpg' }
  let!(:change_image) { ChangeImage.create!(file: File.new("./spec/fixtures/#{filename}"), admin_user: admin_user) }

  before do
    login_as user
  end

  scenario 'successfully', js: true do
    visit clients_path
    expect(page).to_not have_content I18n.t('views.change_text.more_body')
    find('div#change-alert-reveal a', text: I18n.t('views.change_text.more_link_text')).click
    wait_for_ajax
    expect_analytics_events_with_keys('texts_of_change_expand' => ['visitor_id'])
    expect(page).to have_content I18n.t('views.change_text.more_body')

    find('div#change-alert-reveal a', text: I18n.t('views.change_text.more_link_text')).click
    wait_for_ajax
    expect_analytics_events_with_keys('texts_of_change_collapse' => ['visitor_id'])
    expect(page).to_not have_content I18n.t('views.change_text.more_body')
  end
end
