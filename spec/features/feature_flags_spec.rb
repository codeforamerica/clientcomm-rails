require 'rails_helper'

feature 'feature flags' do
  describe 'mass messages' do
    let(:myuser) { create :user }

    before do
      login_as(myuser, :scope => :user)
    end

    context 'enabled' do
      before do
        FeatureFlag.create!(flag: 'mass_messages', enabled: true)
      end

      it 'shows mass messages button' do
        visit clients_path
        expect(page).to have_content 'Mass message'
      end
    end

    context 'disabled' do
      it 'does not show mass messages button' do
        visit clients_path
        expect(page).not_to have_content 'Mass message'
      end
    end
  end

  describe 'templates' do
    let(:myuser) { create :user }
    let(:client) { create :client, user: myuser }
    let(:rr) { ReportingRelationship.find_by(user: myuser, client: client) }

    before do
      login_as(myuser, :scope => :user)
    end

    context 'enabled' do
      before do
        FeatureFlag.create!(flag: 'templates', enabled: true)
      end

      it 'shows templates button' do
        visit reporting_relationship_path(rr)
        expect(page).to have_css '#template-button'
      end
    end

    context 'disabled' do
      it 'does not show templates button' do
        visit reporting_relationship_path(rr)
        expect(page).not_to have_css '#template-button'
      end
    end
  end

  describe 'client status' do
    let(:myuser) { create :user }
    let!(:status) { create :client_status }

    before do
      login_as(myuser, :scope => :user)
      create :client, user: myuser, client_status: status
    end

    context 'enabled' do
      before do
        FeatureFlag.create!(flag: 'client_status', enabled: true)
      end

      it 'shows status radio button' do
        visit new_client_path
        expect(page).to have_css '.radio-button', text: status.name
      end

      it 'shows status on the clients list' do
        visit clients_path
        expect(page).to have_css '.status-banner-container'
        expect(page).to have_css 'th', text: 'Status'
        expect(page).to have_css 'td', text: status.name
      end
    end

    context 'disabled' do
      it 'does not show templates button' do
        visit new_client_path
        expect(page).not_to have_css '.radio-button'
      end

      it 'shows status on the clients list' do
        visit clients_path
        expect(page).not_to have_css '.status-banner-container'
        expect(page).to have_css 'th', text: 'Action'
        expect(page).to have_css 'td', text: 'Manage'
      end
    end
  end
end
