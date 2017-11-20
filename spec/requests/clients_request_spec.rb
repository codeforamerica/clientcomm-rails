require 'rails_helper'

describe 'Clients requests', type: :request do
  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      get clients_path
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'authenticated' do
    let(:user) { create :user }

    before do
      sign_in user
    end

    describe 'POST#create' do
      let(:first_name) { Faker::Name.first_name }
      let(:phone_number) { '1-466-336-4863' }
      let(:notes) { Faker::Lorem.sentence }
      let(:last_name) { Faker::Name.last_name }
      let!(:client_status) { create :client_status }

      subject do
        post clients_path, params: {
          client: {
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            notes: notes,
            client_status_id: client_status.id.to_s
          }
        }
      end

      it 'creates a client' do
        subject

        expect(response.code).to eq '302'
        expect(response).to redirect_to client_messages_path(Client.last)
        expect(Client.count).to eq 1

        client = Client.first
        expect(client.users).to include user
        expect(client.first_name).to eq first_name
        expect(client.last_name).to eq last_name
        expect(client.phone_number).to eq phone_number
        expect(client.notes).to eq notes
        expect(client.client_status).to eq client_status
      end

      it 'tracks the creation of a new client' do
        subject

        client = Client.first

        expect_analytics_events(
          {
            'client_create_success' => {
              'client_id' => client.id
            }
          }
        )
      end

      context 'receives invalid client parameters' do
        let(:last_name) { nil }

        it 'renders new with validation errors' do
          subject

          expect(flash[:alert]).to include 'There was a problem'
          expect(response.code).to eq '200'
          expect(response.body).to include "can't be blank"
          expect(Client.count).to eq 0
        end
      end

      context 'client has a relationship with a user in the same department' do
        context 'client already exists under this user' do
          let!(:client) { create :client, user: user, phone_number: phone_number}
          it 'redirects to the messages page' do
            subject

            expect(response.code).to eq '302'
            expect(response).to redirect_to client_messages_path(client)
            expect(flash[:notice]).to eq 'You already have a client with this phone number.'
          end
        end

        context 'client exists under a different user' do
          let(:other_user) { create :user, department: user.department }
          let!(:client) { create :client, user: other_user, phone_number: phone_number}

          it 'shows an error flash' do
            subject

            expect(response.code).to eq '200'
            expect(flash[:alert]).to include 'There was a problem saving this client.'
            expect(response.body).to include 'This client already exists'
            expect(response.body).to include other_user.full_name
          end
        end
      end
    end

    describe 'POST#update' do
      let(:first_name) { Faker::Name.first_name }
      let(:phone_number) { '+14663364863' }
      let(:notes) { Faker::Lorem.sentence }
      let(:last_name) { Faker::Name.last_name }

      subject do
        client = create :client, user: user

        put client_path(client), params: {
          client: {
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            notes: notes
          }
        }
      end

      it 'updates a client' do
        subject
        client = Client.last

        expect(response.code).to eq '302'
        expect(response).to redirect_to client_messages_path(client)

        expect(client.first_name).to eq first_name
        expect(client.last_name).to eq last_name
        expect(client.phone_number).to eq phone_number
        expect(client.notes).to eq notes
      end

      it 'tracks the creation of a new client' do
        subject

        client = Client.first

        expect_analytics_events(
          {
            'client_edit_success' => {
              'client_id' => client.id
            }
          }
        )
      end

      context 'receives invalid client parameters' do
        let(:last_name) { nil }

        it 'renders edit with validation errors' do
          subject

          expect(flash[:alert]).to include 'There was a problem'
          expect(response.code).to eq '200'
          expect(response.body).to include "can't be blank"
        end
      end
    end

    describe 'GET#index' do
      let!(:another_client) { create :client }

      before do
        create_list :client, 5, user: user
      end

      subject { get clients_path }

      it 'returns a list of clients' do
        subject

        user.clients.each do |client|
          expect(Nokogiri.parse(response.body).to_s).to include("#{client.first_name} #{client.last_name}")
        end

        expect(Nokogiri.parse(response.body).to_s).not_to include("#{another_client.first_name} #{another_client.last_name}")
      end

      context 'there are archived clients' do
        let(:archived_client) { user.clients.first }

        before do
          archived_client.update!(active: false)
        end

        it 'does not return archived clients' do
          subject

          expect(response.body).to_not include("#{archived_client.first_name} #{archived_client.last_name}")
        end
      end

      context 'client status enabled' do
        before do
          FeatureFlag.create!(flag: 'client_status', enabled: true)
          ClientStatus.create!(name: 'Active', followup_date: 30)

          create :client, user: user, client_status: ClientStatus.find_by_name('Active'), last_contacted_at: active_contacted_at
          create :client, user: user, client_status: ClientStatus.find_by_name('Training'), last_contacted_at: training_contacted_at
          create :client, user: user, client_status: ClientStatus.find_by_name('Exited'), last_contacted_at: exited_contacted_at
        end

        subject { get clients_path }

        context 'clients with active statuses require follow ups' do
          let(:active_contacted_at) { Time.now - 26.days }
          let(:training_contacted_at) { nil }
          let(:exited_contacted_at) { nil }

          it 'shows active followup banner' do
            client_id = Client.find_by_client_status_id(ClientStatus.find_by_name('Active').id).id
            subject

            expect(Nokogiri.parse(response.body).text)
              .to include('You have 1 active client due for follow up')
            expect(Nokogiri.parse(response.body).to_s)
              .to include('clients%5B%5D=' + client_id.to_s)
          end
        end
      end

      context 'there is a client with a conversation error' do
        let(:error_client) { user.clients.first }

        before do
          error_client.update!(has_message_error: true)
        end

        it 'shows a error logo' do
          subject

          expect(Nokogiri.parse(response.body).css("tr##{dom_id(error_client)} .icon-warning")).to be_present
        end
      end
    end

    describe 'GET#edit' do
      let(:client) { create :client, user: user }

      subject { get edit_client_path(client) }

      context 'intercom' do
        let(:app_id) { 'test' }

        before do
          @intercom = ENV['INTERCOM_APP_ID']
          ENV['INTERCOM_APP_ID'] = app_id
        end

        after do
          ENV['INTERCOM_APP_ID'] = @intercom
        end

        it 'shows the transfer client section' do
          subject

          expect(response.body).to include('Transfer Client')
        end

        context 'no intercom app ID is set' do
          let(:app_id) { '' }

          it 'does not show the transfer client section' do
            subject

            expect(response.body).to_not include('Transfer Client')
          end
        end
      end
    end
  end
end
