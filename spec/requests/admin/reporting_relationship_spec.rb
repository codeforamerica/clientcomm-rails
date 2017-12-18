require 'rails_helper'

describe 'ReportingRelationships', type: :request, active_job: true do
  let(:department1) { create :department, name: 'AAA' }
  let(:department2) { create :department, name: 'BBB' }
  let(:department3) { create :department, name: 'CCC' }
  let(:user1) { create :user, department: department1 }
  let(:user2) { create :user, department: department1 }
  let(:user3) { create :user, department: department2 }
  let(:user4) { create :user, department: department3 }

  before do
    @admin_user = create :admin_user
    login_as @admin_user, scope: :admin_user
  end

  describe 'POST#create' do
    context 'adding a relationship in a department where the user has no relationships' do
      let(:client) { create :client, users: [user1, user4] }
      let(:department) { user3.department }
      let(:params) do
        {
          reporting_relationship: {
            user: { department_id: department.id, id: user3.id },
            client_id: client.id
          },
          transfer: { note: 'This is a transfer note.' }
        }
      end

      it 'creates the new relationship' do
        perform_enqueued_jobs do
          post admin_reporting_relationships_path, params: params
        end

        active_users = client.active_users

        expect(active_users).to include(user1, user3, user4)
        expect(ReportingRelationship.find_by(user: user1, client: client)).to be_active
        expect(ReportingRelationship.find_by(user: user3, client: client)).to be_active
        expect(ReportingRelationship.find_by(user: user4, client: client)).to be_active

        emails = ActionMailer::Base.deliveries
        to_addrs = emails.map(&:to)
        expect(to_addrs).to contain_exactly([user3.email])
      end

      it 'tracks the transfer action' do
        perform_enqueued_jobs do
          post admin_reporting_relationships_path, params: params
        end

        expect_analytics_events('client_transfer' => {
                                  'admin_id' => @admin_user.id,
                                  'clients_transferred_count' => 1
                                })
      end
    end

    context 'adding a relationship in a department where the user has inactive relationships' do
      context 'creating a new relationship' do
        let(:client) { create :client, users: [user1] }
        let(:department) { user1.department }
        let(:params) do
          {
            reporting_relationship: {
              user: { department_id: department.id, id: user2.id },
              client_id: client.id
            },
            transfer: { note: 'This is a transfer note.' }
          }
        end

        before do
          create_list :message, 5, client: client, user: user1, send_at: Time.now + 1.day
          ReportingRelationship.find_by(client: client, user: user1).update!(active: false)
        end

        it 'creates the new relationship' do
          perform_enqueued_jobs do
            post admin_reporting_relationships_path, params: params
          end

          active_users = client.active_users

          expect(active_users).to include(user2)
          expect(ReportingRelationship.find_by(user: user1, client: client)).to_not be_active
          expect(ReportingRelationship.find_by(user: user2, client: client)).to be_active

          emails = ActionMailer::Base.deliveries
          to_addrs = emails.map(&:to)
          expect(to_addrs).to contain_exactly([user2.email])
        end

        it 'transfers scheduled messages' do
          scheduled_messages = user1.messages.scheduled
          perform_enqueued_jobs do
            post admin_reporting_relationships_path, params: params
          end
          active_users = client.active_users

          expect(active_users).to include(user2)
          expect(active_users).to_not include(user1)
          expect(user2.messages.scheduled).to include(*scheduled_messages.reload)
          expect(ReportingRelationship.find_by(user: user2, client: client)).to be_active
          expect(ReportingRelationship.find_by(user: user1, client: client)).to_not be_active

          emails = ActionMailer::Base.deliveries
          to_addrs = emails.map(&:to)
          expect(to_addrs).to contain_exactly([user2.email])
        end
      end

      context 'reactivating an old relationship' do
        let(:client) { create :client, users: [user1] }
        let(:rr) { ReportingRelationship.find_by(user: user1, client: client) }
        let(:department) { user1.department }
        let(:params) do
          {
            reporting_relationship: {
              client_id: client.id,
              user: {
                department_id: department.id, id: user1.id
              }
            },
            transfer: { note: 'This is a transfer note.' }
          }
        end

        before do
          ReportingRelationship.find_by(client: client, user: user1).update!(active: false)
        end

        it 'reactivates the relationship and tracks the transfer action' do
          perform_enqueued_jobs do
            post admin_reporting_relationships_path, params: params
          end

          active_users = client.active_users
          expect(active_users).to include(user1)
          expect(ReportingRelationship.find_by(user: user1, client: client)).to be_active

          expect_analytics_events('client_transfer' => {
                                    'admin_id' => @admin_user.id,
                                    'clients_transferred_count' => 1
                                  })
        end
      end
    end
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
