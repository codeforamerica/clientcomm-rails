require 'rails_helper'

feature 'feature flags' do
  describe 'scheduled messages' do
    let(:user) { create :user }
    let(:client) { create(:client, user: user) }

    before do
      login_as(user, :scope => :user)
    end

    context 'enabled' do
      before do
        ENV['SCHEDULED_MESSAGES'] = 'true'
        visit client_messages_path(client)
      end

      it 'shows the send later button' do
        expect(page).to have_content 'Send later'
      end
    end

    context 'disabled' do
      before do
        ENV['SCHEDULED_MESSAGES'] = 'false'
        visit client_messages_path(client)
      end

      it 'shows the send later button' do
        expect(page).not_to have_content 'Send later'
      end
    end
  end
end
