require 'rails_helper'

feature 'Twilio', :js do
  after do
    page.driver.headers = { 'X-Twilio-Signature' => nil }
  end

  describe 'POSTs to #incoming_sms' do
    before do
      @unclaimed_email = ENV['UNCLAIMED_EMAIL']
      ENV['UNCLAIMED_EMAIL'] = 'example@example.com'
    end

    after do
      ENV['UNCLAIMED_EMAIL'] = @unclaimed_email
    end

    context 'from an unknown user' do
      let(:phone_number) { 'just some phone number' }
      let(:department) { create :department, phone_number: phone_number }
      let!(:unclaimed_user) { create(:user, department: department, email: ENV['UNCLAIMED_EMAIL']) }

      it 'routes messages to user for unclaimed messages' do
        message_params = twilio_new_message_params to_number: phone_number
        twilio_post_sms message_params

        login_as(unclaimed_user, scope: :user)

        visit root_path

        unknown_phone_number = message_params['From']
        message_body = message_params['Body']
        expect(page).to have_css '.data-table td', text: unknown_phone_number
        find('td', text: unknown_phone_number).click
        expect(page).to have_content PhoneNumberParser.format_for_display(unknown_phone_number)
        expect(page).to have_content message_body
      end
    end
  end
end
