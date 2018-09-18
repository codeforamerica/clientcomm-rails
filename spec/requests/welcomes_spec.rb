require 'rails_helper'

describe 'Reporting Relationship Welcome Requests', type: :request, active_job: true do
  include ActiveJob::TestHelper

  let(:user) { create :user }
  let!(:client) { create :client, user: user }
  let(:rr) { ReportingRelationship.find_by(user: user, client: client) }

  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      get new_reporting_relationship_welcome_path rr
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'authenticated' do
    before do
      sign_in user
    end

    describe 'GET#new' do
      subject { get new_reporting_relationship_welcome_path(rr) }

      it 'tracks a visit to the welcome form' do
        subject
        expect(response.code).to eq '200'
        expect_analytics_events(
          'welcome_prompt_view' => {
            'client_id' => client.id
          }
        )
      end
    end
  end
end
