require 'rails_helper'

describe 'Transfers requests', type: :request, active_job: true do
  let(:department) { create :department }
  let(:user) { create :user, department: department }
  let(:transfer_user) { create :user, department: department }
  let!(:client) { create :client, user: user }

  before do
    sign_in user
  end

  describe 'POST#create' do
    subject do
      post transfers_path, params: {
        transfer: {
          note: 'some note',
          client_id: client.id,
          user_id: transfer_user.id
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
      expect(body).to include('some note')

      expect_most_recent_analytics_event(
        'client_transfer' => {
          'clients_transferred_count' => 1,
          'transferred_by' => 'user',
          'has_transfer_note' => true
        }
      )
    end

    context 'user_id is blank' do
      subject do
        post transfers_path, params: {
          transfer: {
            note: 'some note',
            client_id: client.id,
            user_id: ''
          }
        }
      end

      it 'redirects back to the form' do
        subject
        expect(response).to redirect_to edit_client_path client.id
      end
    end
  end
end
