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
end
