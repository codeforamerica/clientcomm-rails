require 'rails_helper'

describe 'Reporting Relationship Requests', type: :request, active_job: true do
  let(:department) { create :department }
  let(:user) { create :user, department: department }
  let(:transfer_user) { create :user, department: department }
  let(:transfer_note) { Faker::Lorem.characters(10) }
  let!(:client) { create :client, user: user }
  let!(:scheduled_messages) { create_list :message, 5, client: client, user: user, send_at: Time.now + 1.day }

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

    it 'transfers scheduled messages' do
      expect(user.messages).to include(*scheduled_messages)
      expect(transfer_user.messages).to_not include(*scheduled_messages)
      subject
      expect(user.messages).to_not include(*scheduled_messages.map(&:reload))
      expect(transfer_user.messages.reload).to include(*scheduled_messages)
    end

    it 'creates transfer markers' do
      expect(transfer_user.messages.transfer_markers).to be_empty
      time = Time.now
      travel_to time do
        subject
      end
      expect(transfer_user.messages.transfer_markers.count).to eq(1)
      marker_from = transfer_user.messages.transfer_markers.first
      expect(marker_from.client).to eq(client)

      transfer_message_from_body = I18n.t(
        'messages.transferred_from',
        client_full_name: client.full_name,
        user_full_name: user.full_name,
        time: time
      )
      expect(marker_from.body).to eq(transfer_message_from_body)

      expect(user.messages.transfer_markers.count).to eq(1)
      marker_to = user.messages.transfer_markers.first
      expect(marker_to.client).to eq(client)

      transfer_message_to_body = I18n.t(
        'messages.transferred_to',
        user_full_name: transfer_user.full_name,
        time: time
      )
      expect(marker_to.body).to eq(transfer_message_to_body)
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

    context 'user is the unclaimed user' do
      let!(:unclaimed_messages) { create_list :message, 3, client: client, user: user }

      before do
        department.update!(unclaimed_user: user)
      end

      it 'transfers messages received by the unclaimed user' do
        expect(user.messages).to include(*unclaimed_messages)
        expect(transfer_user.messages).to_not include(*unclaimed_messages)
        subject
        expect(user.messages).to_not include(*unclaimed_messages.map(&:reload))
        expect(transfer_user.messages.reload).to include(*unclaimed_messages)
      end
    end
  end
end
