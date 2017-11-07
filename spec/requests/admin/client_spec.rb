require 'rails_helper'

describe 'Clients', type: :request, active_job: true do
  let(:user) { create :user }
  let(:user_2) { create :user }
  let(:clients) { create_list :client, 5, user: user }

  before do
    @admin_user = create :admin_user
    login_as @admin_user, scope: :admin_user
  end

  describe 'POST#batch_transfer' do
    let(:params) do
      {
        batch_action: :transfer,
        batch_action_inputs: { user: user_2.id }.to_json,
        collection_selection: clients.map(&:id)
      }
    end

    before do
      clients.each do |client|
        create_list :message, 2, client: client, user: user, send_at: Time.now + 1.day
      end
    end

    it 'transfers clients and their scheduled messages' do
      post '/admin/clients/batch_action', params: params

      clients.each do |client|
        expect(client.reload.user).to eq(user_2)
        expect(user_2.messages.scheduled).to include(*client.messages.scheduled)
      end
    end

    it 'tracks the transfer action' do
      post '/admin/clients/batch_action', params: params

      expect_analytics_events({
        'client_transfer' => {
          'admin_id' => @admin_user.id,
          'clients_transferred_count' => 5
        }
      })
    end
  end

  describe 'PUT#update' do
    before do
      create_list :message, 5, client: clients.first, user: user, send_at: Time.now + 1.day
    end

    context 'transferring a client' do
      let(:client) { clients.first }
      let(:params) do
        { client: { user_id: user_2.id } }
      end

      it 'transfers scheduled messages' do
        perform_enqueued_jobs do
          put admin_client_path(client), params: params
        end

        expect(client.reload.user).to eq(user_2)
        expect(user_2.messages.scheduled).to include(*client.messages.scheduled)

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

    context 'unarchiving a client' do
      before do
        clients.first.update(active: false)
      end

      it 'does not send a transfer email' do
        client = clients.first

        perform_enqueued_jobs do
          put admin_client_path(client), params: {
            client: {
              user_id: client.user.id,
              active: true
            }
          }
        end

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end
end
