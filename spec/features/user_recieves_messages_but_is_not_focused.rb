require 'rails_helper'

feature 'sending messages', active_job: true do
  let(:rr) { create :reporting_relationship, active: true }
  let(:user) { rr.user }
  let(:client) { rr.client }
  before do
    login_as(user, scope: :user)
    create_list :text_message, 10, reporting_relationship: rr, send_at: Time.zone.now - 1.day, read: true
  end

  scenario 'user recieves message', :js, active_job: true do
    step 'when user goes to messages page' do
      visit reporting_relationship_path(rr)
      wait_for_ajax
    end

    step 'client responds' do
      # post a message to the twilio endpoint from the user
      perform_enqueued_jobs do
        twilio_post_sms(twilio_new_message_params(
                          from_number: client.phone_number,
                          to_number: user.department.phone_number
        ))
      end

      # there's a message with the correct contents
      expect(page).to have_css '.message--inbound div', text: twilio_message_text
      sleep 0.3
      wait_for_ajax
      expect(page).not_to have_css '.message--inbound.unread'
      expect(page).to have_css "link[rel='shortcut icon'][href='#{ActionController::Base.helpers.asset_path('favicon.read.png')}']"
    end

    step 'scroll to top' do
      page.execute_script('document.body.scrollTop = document.documentElement.scrollTop = 0;')
      page.execute_script('messagesToBottom = function() {};') # disable autoscroll
    end

    step 'client responds' do
      # post a message to the twilio endpoint from the user
      perform_enqueued_jobs do
        twilio_post_sms(twilio_new_message_params(
                          from_number: client.phone_number,
                          to_number: user.department.phone_number
        ))
      end
      # there's a message with the correct contents
      expect(page).to have_css '.message--inbound div', text: twilio_message_text
      wait_for_ajax
      expect(page).to have_css '.message--inbound.unread'
      expect(page).to have_css "link[rel='shortcut icon'][href='#{ActionController::Base.helpers.asset_path('favicon.unread.png')}']"
    end

    step 'scroll to bottom' do
      page.execute_script('window.scrollTo(0,document.body.scrollHeight);')
      expect(page).to_not have_css '.message--inbound.unread'
      sleep 0.3
      wait_for_ajax
      expect(rr.messages.unread).to be_empty
      expect(page).to have_css "link[rel='shortcut icon'][href='#{ActionController::Base.helpers.asset_path('favicon.read.png')}']"
    end
  end
end
