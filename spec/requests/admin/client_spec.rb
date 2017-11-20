require 'rails_helper'

describe 'Clients', type: :request, active_job: true do
  let(:department1) { create :department }
  let(:department2) { create :department }
  let(:department3) { create :department }
  let(:user1) { create :user, department: department1 }
  let(:user2) { create :user, department: department1 }
  let(:user3) { create :user, department: department2 }
  let(:user4) { create :user, department: department3 }
  let(:client) { create :client, users: [user1, user4] }

  before do
    @admin_user = create :admin_user
    login_as @admin_user, scope: :admin_user
  end

  describe 'PUT#update' do
    before do
      create_list :message, 5, client: client, user: user1, send_at: Time.now + 1.day
    end

    context 'transferring a client' do
      it 'transfers scheduled messages' do
        scheduled_messages = user1.messages.scheduled
        perform_enqueued_jobs do
          put admin_client_path(client), params: {
            client: {
              user_ids: [user2.id, user3.id]
            }
          }
        end

        expect(client.reload.users).to include(user2, user3)
        expect(client.reload.users).to_not include(user1, user4)
        expect(user2.messages.scheduled).to include(*scheduled_messages.reload)
        expect(ReportingRelationship.find_by(user: user4, client: client)).to_not be_active
        expect(ReportingRelationship.find_by(user: user1, client: client)).to_not be_active

        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it 'triggers the notification mailer' do
        message_delivery = instance_double(ActionMailer::MessageDelivery)

        expect(NotificationMailer).to receive(:client_transfer_notification).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)

        put admin_client_path(client), params: params
      end

      it 'tracks the transfer action' do
        perform_enqueued_jobs do
          put admin_client_path(client), params: params
        end

        expect_analytics_events({
                                  'client_transfer' => {
                                    'admin_id' => @admin_user.id,
                                    'clients_transferred_count' => 1
                                  }
                                })
      end
    end
  end
end
