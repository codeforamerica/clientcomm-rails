require 'rails_helper'

describe 'Mass messages requests', type: :request, active_job: true do
  let(:department) { create :department }
  let(:user) { create :user, department: department }

  before do
    sign_in user
  end

  describe 'POST#create' do
    let!(:client_1) { create :client, user: user }
    let!(:client_2) { create :client, user: user }
    let!(:client_3) { create :client, user: user }
    let(:message_body) { 'hello this is message one' }
    let(:clients) { ['', client_1.id, client_3.id] }

    before do
      post mass_messages_path, params: {
        mass_message: {
          message: message_body,
          clients: clients
        }
      }
    end

    it 'sends message to multiple clients' do
      expect(ScheduledMessageJob).to have_been_enqueued.twice

      expect(user.messages.count).to eq 2
      expect(client_1.messages.count).to eq 1
      expect(client_1.messages.first.body).to eq message_body
      expect(client_1.messages.first.number_from).to eq department.phone_number
      expect(client_2.messages.count).to eq 0
      expect(client_3.messages.count).to eq 1
      expect(client_3.messages.first.body).to eq message_body
      expect(client_3.messages.first.number_from).to eq department.phone_number
    end

    it 'sends an analytics event for each message in mass message' do
      expect_analytics_events(
        'message_send' => {
          'mass_message' => true
        }
      )

      expect_analytics_event_sequence(
        'login_success',
        'message_send',
        'message_send',
        'mass_message_send'
      )
    end

    it 'sends a single mass_message_send event with recipient_count' do
      expect_analytics_events(
        'mass_message_send' => {
          'recipients_count' => 2
        }
      )
    end

    context 'no message body inputted' do
      let(:message_body) { '' }

      it 're-renders the page with errors' do
        expect(response.body).to include 'You need to add a message.'
      end
    end

    context 'no message recipients selected' do
      let(:message_body) { '' }
      let(:clients) { [''] }

      it 're-renders the page with errors' do
        expect(response.body).to include 'You need to pick at least one recipient.'
      end
    end
  end

  describe 'GET#new' do
    let(:params) { nil }

    before do
      create_list :client, 3, user: user
    end

    subject { get new_mass_message_path, params: params }

    it 'tracks a visit to the new mass message page' do
      subject

      expect(response.code).to eq '200'
      expect_analytics_events(
        'mass_message_compose_view' => {
          'clients_count' => 3
        }
      )
    end

    context 'using a url to pre-populate' do
      let(:params) { { clients: [user.clients[0].id, user.clients[2].id] } }

      it 'renders checkboxes selected correctly' do
        subject

        clients = user.clients

        expect(response.body).to include("value=\"#{clients[0].id}\" checked=\"checked\"")
        expect(response.body).to include("value=\"#{clients[2].id}\" checked=\"checked\"")
        expect(response.body).to include("value=\"#{clients[1].id}\" name")
      end
    end

    context 'client status feature flag enabled' do
      let(:status) { create :client_status }

      before do
        FeatureFlag.create!(flag: 'client_status', enabled: true)
      end

      it 'renders client list with status column' do
        create :client, client_status: status, user: user

        get new_mass_message_path

        expect(response.body).to include 'Status'
        expect(response.body).to include status.name
      end
    end
  end
end
