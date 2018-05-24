require 'rails_helper'

feature 'creating and editing scheduled messages', active_job: true do
  let(:userone) { create :user }
  let(:clientone) { create :client, user: userone }
  let(:rrone) { ReportingRelationship.find_by(client: clientone, user: userone) }
  let(:past_date) { Time.zone.now - 1.month }
  let!(:reminder) { create :court_reminder, reporting_relationship: rrone, send_at: past_date }
  scenario 'user views court reminder', :js do
    step 'when user logs in' do
      login_as(userone, scope: :user)
    end

    step 'when user goes to messages page' do
      visit reporting_relationship_path(rrone)
      expect(page).to have_content reminder.body
    end
  end
end
