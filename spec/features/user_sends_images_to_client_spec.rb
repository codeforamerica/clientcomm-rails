
require 'rails_helper'

feature 'user sends images', active_job: true do
  let(:message_body) { 'You have an appointment tomorrow at 10am' }
  let(:rr) { create :reporting_relationship }
  let(:user) { rr.user }
  let(:client) { rr.client }

  before do
    login_as(user, scope: :user)
  end

  scenario 'user sends images to client', :js, active_job: true do
    step 'when user goes to messages page' do
      visit reporting_relationship_path(rr)
      expect(page).not_to have_css('#file-name-preview')
    end

    step 'uploads csv file' do
      attach_file('message[attachments][][media]', Rails.root + 'spec/fixtures/court_dates.csv', make_visible: true)
      results = page.evaluate_script('$("#message_attachments_0_media").val()==""')
      expect(page.evaluate_script(results)).to equal true
      expect(page).to have_css '#file-name-preview span.image-help-text', text: 'You can only send .gif, .png, and .jpg files'
      expect(page).to have_css('#send_message:disabled')
    end

    step 'uploads large image file' do
      attach_file('message[attachments][][media]', Rails.root + 'spec/fixtures/large_image.jpg', make_visible: true)
      results = page.evaluate_script('$("#message_attachments_0_media").val()==""')
      expect(page.evaluate_script(results)).to equal true
      expect(page).to have_css '#file-name-preview span.image-help-text', text: 'You can only send files <5MB in size'
      expect(page).to have_css('#send_message:disabled')
    end

    step 'uploads image' do
      attach_file('message[attachments][][media]', Rails.root + 'spec/fixtures/fluffy_cat.jpg', make_visible: true)

      expect(page).to have_button('Send later', disabled: true)
      expect(page).to have_css '#file-name-preview span.image-help-text', text: 'fluffy_cat.jpg'
    end

    step 'user clears image' do
      perform_enqueued_jobs do
        find('#image-cancel').click
        results = page.evaluate_script('$("#message_attachments_0_media").val()==""')
        expect(page.evaluate_script(results)).to equal true
        expect(page).to_not have_css '#file-name-preview span.image-help-text', text: 'fluffy_cat.jpg'
        expect(page).to have_css('#send_message:disabled')
      end
    end

    step 'user sends image' do
      attach_file('message[attachments][][media]', Rails.root + 'spec/fixtures/fluffy_cat.jpg', make_visible: true)

      expect(page).to have_button('Send later', disabled: true)
      expect(page).to have_css '#file-name-preview span.image-help-text', text: 'fluffy_cat.jpg'

      perform_enqueued_jobs do
        click_on 'send_message'
        expect(page).to have_css '.message--outbound img'
        expect(page).to_not have_css '#file-name-preview span.image-help-text', text: 'fluffy_cat.jpg'
      end
    end
  end
end
