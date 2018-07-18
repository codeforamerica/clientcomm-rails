require 'rails_helper'

feature 'Twilio', :js do
  after do
    page.driver.headers = { 'X-Twilio-Signature' => nil }
  end

  describe 'POSTs to #incoming_sms' do
    context 'from an unknown user' do
      let(:phone_number) { 'just some phone number' }
      let(:department) { create :department, phone_number: phone_number }
      let!(:unclaimed_user) { create :user, department: department }

      before do
        department.unclaimed_user = unclaimed_user
        department.save!
      end

      scenario 'receiving unclaimed messages' do
        message_params = twilio_new_message_params to_number: phone_number

        step 'the message is received by the unclaimed user' do
          twilio_post_sms message_params
          login_as(unclaimed_user, scope: :user)
          visit root_path

          expect(page).to have_css '.data-table td', text: message_params['From']
          expect(page).to have_css '.unread td', text: message_params['From']
        end

        step 'the message and auto-reply are on the conversation page' do
          find('td', text: message_params['From']).click
          expect(page).to have_content PhoneNumberParser.format_for_display(message_params['From'])
          expect(page).to have_content message_params['Body']
          expect(page).to have_content I18n.t('message.unclaimed_response')
        end

        step 'the conversation has been marked read' do
          find('#home-button a').click
          expect(page).to have_current_path(clients_path)
          expect(page).to have_css '.read td', text: message_params['From']
        end
      end
    end
  end
end
