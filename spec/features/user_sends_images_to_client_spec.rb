
require 'rails_helper'

feature 'user sends images', active_job: true do
  let(:message_body) { 'You have an appointment tomorrow at 10am' }
  let(:rr) { create :reporting_relationship }
  let(:user) { rr.user }
  let(:client) {rr.client}

  before do
    login_as(user, scope: :user)
  end

  scenario 'user sends images to client', :js, active_job: true do
    step 'when user goes to messages page' do
      visit reporting_relationship_path(rr)
    end

    step 'uploads image' do

      attach_file('message[attachments][][media]', Rails.root + 'spec/fixtures/fluffy_cat.jpg', make_visible: true)

      expect(page).to have_button('Send later', disabled: true)

    end

    step 'user sends image' do

      perform_enqueued_jobs do
        click_on 'send_message'
        expect(page).to have_css '.message--outbound img'
      end

    end

    step 'uploads csv file' do

      attach_file('message[attachments][][media]', Rails.root + 'spec/fixtures/court_dates.csv', make_visible: true)
			results = page.evaluate_script('$("#message_attachments_0_media").val()')
			expect(page.evaluate_script(results)).to equal 'true'
      expect(page).to have_css '#file-name-preview', text: 'You can only send .png and .jpg files'

    end

    end
  end
