require 'rails_helper'

describe 'Reporting Relationship Requests', type: :request, active_job: true do
  let(:department) { create :department }
  let(:user) { create :user, department: department }
  let(:transfer_user) { create :user, department: department }
  let(:transfer_note) { Faker::Lorem.characters(10) }
  let!(:client) { create :client, user: user }

  before do
    sign_in user
  end

  describe 'POST#create' do
    subject do
      post reporting_relationships_path, params: {
        transfer_note: transfer_note,
        reporting_relationship: {
          user_id: transfer_user.id,
          client_id: client.id
        }
      }
    end

    it 'transfers the client' do
      expect(user.clients.active).to include client
      expect(transfer_user.clients.active).to_not include client

      perform_enqueued_jobs do
        subject
      end

      expect(user.clients.active).to_not include client
      expect(transfer_user.clients.active).to include client

      emails = ActionMailer::Base.deliveries
      to_add = emails.map(&:to)
      body = emails.first.body.encoded
      expect(to_add).to contain_exactly([transfer_user.email])
      expect(body).to include("#{user.full_name} has transferred a client to you")
      expect(body).to include(transfer_note)

      expect_most_recent_analytics_event(
        'client_transfer' => {
          'clients_transferred_count' => 1,
          'transferred_by' => 'user',
          'has_transfer_note' => true
        }
      )
    end

    context 'transfer user has an inactive relationship' do
      before do
        create :reporting_relationship, user: transfer_user, client: client, active: false
      end

      it 'restores the relationship' do
        perform_enqueued_jobs do
          subject
        end

        expect(user.clients.active).to_not include client
        expect(transfer_user.clients.active).to include client
      end
    end

    context 'user_id is blank' do
      subject do
        post reporting_relationships_path, params: {
          reporting_relationship: {
            user_id: nil,
            client_id: client.id
          }
        }
      end

      it 'renders an error' do
        subject
        path = 'activerecord.errors.models.reporting_relationship.attributes.user.blank'
        expect(response.body).to include I18n.t path
      end

      it 'does not deactivate the original rr' do
        subject
        expect(ReportingRelationship.find_by(client_id: client.id, user_id: user.id)).to be_active
      end
    end
  end
end
