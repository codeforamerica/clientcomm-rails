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
      let(:phone_number) { '+14663364863' }
      let(:notes) { Faker::Lorem.sentence }
      let(:last_name) { Faker::Name.last_name }

      subject do
        post clients_path, params: {
          client: {
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            notes: notes
          }
        }
      end

      it 'creates a client' do
        subject

        expect(response.code).to eq '302'
        expect(response).to redirect_to client_messages_path(Client.last)
        expect(Client.count).to eq 1

        client = Client.first
        expect(client.user).to eq user
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

          expect(response.code).to eq '200'
          expect(response.body).to include "can't be blank"
          expect(Client.count).to eq 0
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

        it 'renders new with validation errors' do
          subject

          expect(response.code).to eq '200'
          expect(response.body).to include "can't be blank"
        end
      end
    end

    describe 'get#index' do
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

    describe 'post#archive' do
      let(:client) { create :client, user: user, created_at: Time.zone.local(2003, 01, 01, 01, 01, 01) }
      subject { post client_archive_path(client), params: { client: { active: false } } }

      it 'shows a confirmation page' do
        travel_to Time.zone.local(2003, 03, 24, 01, 04, 44) do
          subject
        end

        expect(Nokogiri.parse(response.body).to_s).to include("#{client.first_name} #{client.last_name} will no longer appear in ClientComm")

        expect(client.reload.active).to eq(false)

        expect_analytics_events(
          {
            'client_archive_success' => {
              'client_id' => client.id,
              'client_duration' => 82
            }
          }
        )
      end
    end
  end
end
