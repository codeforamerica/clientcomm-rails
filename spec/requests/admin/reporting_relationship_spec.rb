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
            client_id: client.id,
            user: { department_id: department.id, id: user3.id }
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
              client_id: client.id,
              user: { department_id: department.id, id: user2.id }
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
          scheduled_messages_count = scheduled_messages.count
          perform_enqueued_jobs do
            post admin_reporting_relationships_path, params: params
          end
          active_users = client.active_users

          expect(active_users).to include(user2)
          expect(active_users).to_not include(user1)
          expect(user2.messages.scheduled.count).to eq(scheduled_messages_count)
          expect(user2.messages.scheduled).to include(*scheduled_messages.reload)
          expect(ReportingRelationship.find_by(user: user2, client: client)).to be_active
          expect(ReportingRelationship.find_by(user: user1, client: client)).to_not be_active

          emails = ActionMailer::Base.deliveries
          to_addrs = emails.map(&:to)
          expect(to_addrs).to contain_exactly([user2.email])
        end
        context 'when the transfer note is empty' do
          let(:params) do
            {
              reporting_relationship: {
                client_id: client.id,
                user: { department_id: department.id, id: user2.id }
              },
              transfer: { note: '' }
            }
          end

          it 'does not render the message message well' do
            perform_enqueued_jobs do
              post admin_reporting_relationships_path, params: params
            end

            active_users = client.active_users

            expect(active_users).to include(user2)
            expect(ReportingRelationship.find_by(user: user1, client: client)).to_not be_active
            expect(ReportingRelationship.find_by(user: user2, client: client)).to be_active

            emails = ActionMailer::Base.deliveries
            email = emails.first
            expect(email.body.encoded).to_not include 'message-well'
            to_addrs = emails.map(&:to)
            expect(to_addrs).to contain_exactly([user2.email])
          end
        end
      end

      context 'reactivating an old relationship' do
        let(:client) { create :client, users: [user1] }
        let(:department) { user1.department }
        let(:params) do
          {
            reporting_relationship: {
              client_id: client.id,
              user: { department_id: department.id, id: user1.id }
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
    let!(:scheduled_messages) { create_list :message, 5, client: client, user: user1, send_at: Time.now + 1.day }
    let!(:messages) { create_list :message, 2, client: client, user: user1 }

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
        expect(user1.messages.scheduled).to include(*scheduled_messages.map(&:reload))

        perform_enqueued_jobs do
          put admin_reporting_relationship_path(rr.id), params: params
        end

        active_users = client.active_users

        expect(active_users).to include(user2, user4)
        expect(active_users).to_not include(user1)
        expect(user1.messages.scheduled).to_not include(*scheduled_messages.map(&:reload))
        expect(user2.messages.scheduled).to include(*scheduled_messages.map(&:reload))
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

      it 'creates transfer markers' do
        expect(user2.messages.transfer_markers).to be_empty
        time = Time.now

        travel_to time do
          perform_enqueued_jobs do
            put admin_reporting_relationship_path(rr.id), params: params
          end
        end

        expect(user2.messages.transfer_markers.count).to eq(1)
        marker_from = user2.messages.transfer_markers.first
        expect(marker_from.client).to eq(client)

        transfer_message_from_body = I18n.t(
          'messages.transferred_from',
          client_full_name: client.full_name,
          user_full_name: user1.full_name
        )
        expect(marker_from.body).to eq(transfer_message_from_body)

        expect(user1.messages.transfer_markers.count).to eq(1)
        marker_to = user1.messages.transfer_markers.first
        expect(marker_to.client).to eq(client)

        transfer_message_to_body = I18n.t(
          'messages.transferred_to',
          user_full_name: user2.full_name
        )
        expect(marker_to.body).to eq(transfer_message_to_body)
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

      context 'the client is transferred from the unclaimed user' do
        let(:unclaimed_user) { create :user, department: department }
        let(:unclaimed_client) { create :client, users: [unclaimed_user] }
        let!(:unclaimed_messages) { create_list :message, 3, client: unclaimed_client, user: unclaimed_user }
        let(:unclaimed_rr) do
          ReportingRelationship.find_by(
            user: unclaimed_user, client: unclaimed_client
          )
        end
        let(:params) do
          {
            reporting_relationship: { user: { department_id: department.id, id: user1.id } },
            transfer: { note: 'This is a transfer note.' },
            id: unclaimed_rr.id
          }
        end

        before do
          department.update!(unclaimed_user: unclaimed_user)
        end

        it 'transfers messages received by the unclaimed user' do
          expect(unclaimed_user.messages).to include(*unclaimed_messages.map(&:reload))

          perform_enqueued_jobs do
            put admin_reporting_relationship_path(unclaimed_rr.id), params: params
          end
          active_users = unclaimed_client.active_users

          expect(active_users).to include(user1)
          expect(active_users).to_not include(unclaimed_user)
          expect(unclaimed_user.messages).to_not include(*unclaimed_messages.map(&:reload))
          expect(user1.messages).to include(*unclaimed_messages.map(&:reload))
          expect(ReportingRelationship.find_by(user: user1, client: unclaimed_client)).to be_active
          expect(ReportingRelationship.find_by(user: unclaimed_user, client: unclaimed_client)).to_not be_active

          emails = ActionMailer::Base.deliveries
          to_addrs = emails.map(&:to)
          expect(to_addrs).to contain_exactly([user1.email])
        end

        it 'does not show the TO transfer marker on the recipient conversation' do
          perform_enqueued_jobs do
            put admin_reporting_relationship_path(unclaimed_rr.id), params: params
          end

          expect(unclaimed_user.messages.map(&:body)).to include(I18n.t('messages.transferred_to', user_full_name: user1.full_name))
          expect(user1.messages.map(&:body)).to_not include(I18n.t('messages.transferred_to', user_full_name: user1.full_name))
        end
      end
    end
  end
end
