require 'rails_helper'

describe 'ReportingRelationships', type: :request, active_job: true do
  let(:department1) { create :department, name: 'AAA' }
  let(:department2) { create :department, name: 'BBB' }
  let(:department3) { create :department, name: 'CCC' }
  let(:user1) { create :user, department: department1 }
  let(:user2) { create :user, department: department1 }
  let(:user4) { create :user, department: department3 }

  before do
    @admin_user = create :admin_user
    login_as @admin_user, scope: :admin_user
  end

  describe 'PUT#update' do
    before do
      create_list :message, 5, client: client, user: user1, send_at: Time.now + 1.day
    end

    context 'transferring a client' do
      let(:client) { create :client, users: [user1, user4] }
      let(:rr) { ReportingRelationship.find_by(user: user1, client: client) }
      let(:department) { user1.department }
      let(:params) do
        {
          reporting_relationship: { user: { department_id: department.id, id: user2.id } },
          transfer: { note: 'This is a transfer note.' },
          id: rr.id
        }
      end

      it 'transfers scheduled messages' do
        scheduled_messages = user1.messages.scheduled
        perform_enqueued_jobs do
          put admin_reporting_relationship_path(rr.id), params: params
        end
        active_users = client.active_users

        expect(active_users).to include(user2, user4)
        expect(active_users).to_not include(user1)
        expect(user2.messages.scheduled).to include(*scheduled_messages.reload)
        expect(ReportingRelationship.find_by(user: user2, client: client)).to be_active
        expect(ReportingRelationship.find_by(user: user4, client: client)).to be_active
        expect(ReportingRelationship.find_by(user: user1, client: client)).to_not be_active

        emails = ActionMailer::Base.deliveries
        to_addrs = emails.map(&:to)
        expect(to_addrs).to contain_exactly([user2.email])
      end

      it 'disassociates a user if no user is selected' do
        active_users = client.active_users
        expect(active_users.length).to eq(2)

        perform_enqueued_jobs do
          put admin_reporting_relationship_path(rr.id), params: {
            reporting_relationship: { user: { department_id: department.id, id: '' } },
            transfer: { note: '' },
            id: rr.id
          }
        end

        active_users = client.active_users
        expect(active_users.length).to eq(1)
        expect(ReportingRelationship.find_by(user: user1, client: client)).to_not be_active
      end

      context 'the user does not change' do
        it 'does not send unnecessary notifications' do
          perform_enqueued_jobs do
            put admin_reporting_relationship_path(rr.id), params: {
              reporting_relationship: { user: { department_id: department.id, id: user1.id } },
              transfer: { note: '' },
              id: rr.id
            }
          end

          active_users = client.active_users
          expect(ActionMailer::Base.deliveries).to be_empty
          expect(active_users).to include(user1, user4)
        end
      end

      it 'tracks the transfer action' do
        perform_enqueued_jobs do
          put admin_reporting_relationship_path(rr.id), params: params
        end

        expect_analytics_events('client_transfer' => {
                                  'admin_id' => @admin_user.id,
                                  'clients_transferred_count' => 1
                                })
      end
    end
  end
end
