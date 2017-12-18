require 'rails_helper'

describe 'Clients requests', type: :request do
  include ActiveJob::TestHelper

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

    describe 'GET#new' do
      let(:client) { create :client, user: user }
      subject { get edit_client_path(client) }

      it 'tracks a visit to the edit client form' do
        subject
        expect(response.code).to eq '200'
        expect_analytics_events_happened('client_edit_view')
      end
    end

    describe 'POST#create' do
      let(:first_name) { Faker::Name.first_name }
      let(:phone_number) { '+14663364863' }
      let(:notes) { Faker::Lorem.sentence }
      let(:last_name) { Faker::Name.last_name }
      let!(:client_status) { create :client_status }

      subject do
        post clients_path, params: {
          client: {
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            reporting_relationships_attributes: {
              '0': {
                user_id: user.id,
                notes: notes,
                client_status_id: client_status.id.to_s
              }
            }
          }
        }
      end

      it 'creates a client' do
        subject

        expect(response.code).to eq '302'
        expect(response).to redirect_to client_messages_path(Client.last)
        expect(Client.count).to eq 1

        client = Client.first
        rr = client.reporting_relationships.find_by(user: user)
        expect(client.users).to include user
        expect(client.first_name).to eq first_name
        expect(client.last_name).to eq last_name
        expect(client.phone_number).to eq phone_number
        expect(rr.notes).to eq notes
        expect(rr.client_status).to eq client_status
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
        context 'receives empty last name' do
          let(:last_name) { nil }

          it 'renders new with validation errors' do
            subject

            expect(flash[:alert]).to include 'There was a problem'
            expect(response.code).to eq '200'
            expect(response.body).to include "can't be blank"
            expect(Client.count).to eq 0
          end
        end

        context 'receives invalid phone number' do
          let(:bad_number) { '(212) 55-5236' }
          let(:phone_number) { bad_number }

          it 'renders new with invalid phone number validation error' do
            allow(SMSService.instance).to receive(:number_lookup)
              .with(phone_number: bad_number)
              .and_raise(SMSService::NumberNotFound)

            subject

            expect(flash[:alert]).to include 'There was a problem'
            expect(response.code).to eq '200'
            expect(response.body).to include 'not a valid phone number'
            expect(Client.count).to eq 0
          end
        end
      end

      context 'client has a relationship with a user in the same department' do
        context 'client already exists under this user' do
          let!(:client) { create :client, user: user, phone_number: phone_number }
          let(:abnormal_number) { '1-466-336-4863' }

          subject do
            post clients_path, params: {
              client: {
                first_name: first_name,
                last_name: last_name,
                phone_number: abnormal_number,
                reporting_relationships_attributes: {
                  '0': {
                    user_id: user.id,
                    notes: notes,
                    client_status_id: client_status.id.to_s
                  }
                }
              }
            }
          end

          it 'redirects to the messages page' do
            allow(SMSService.instance).to receive(:number_lookup)
              .with(phone_number: abnormal_number)
              .and_return(phone_number)

            subject

            expect(response.code).to eq '302'
            expect(response).to redirect_to client_messages_path(client)
            expect(flash[:notice]).to eq 'You already have a client with this phone number.'
          end

          context 'client has a prior, inactive, relationship with this user' do
            let!(:client) { create :client, user: user, phone_number: phone_number, active: false }

            it 'redirects to the messages page' do
              allow(SMSService.instance).to receive(:number_lookup)
                .with(phone_number: abnormal_number)
                .and_return(phone_number)

              subject

              expect(response.code).to eq '302'
              expect(response).to redirect_to client_messages_path(client)
              expect(client.reporting_relationships.find_by(user: user)).to be_active
            end
          end
        end

        context 'client exists under a different user' do
          let(:other_user) { create :user, department: user.department }
          let!(:client) { create :client, user: other_user, phone_number: phone_number }

          it 'shows an error flash' do
            subject

            expect(response.code).to eq '200'
            expect(flash[:alert]).to include 'There was a problem saving this client.'
            expect(response.body).to include 'This client already exists'
            expect(response.body).to include other_user.full_name
          end
        end
      end

      context 'client has a relationship with a user in a different department' do
        let(:first_name) { 'Mark' }
        let(:last_name) { 'Zak' }
        let(:other_user) { create :user }
        let!(:client) { create :client, first_name: first_name, last_name: last_name, user: other_user, phone_number: phone_number }

        it 'should render the confirmation page' do
          expect { subject }.to_not(change { ReportingRelationship.count })

          expect(response.code).to eq '200'

          expect(response.body).to include(first_name)
          expect(response.body).to include(last_name)
          expect(response.body).to include(phone_number)
          expect(response.body).to include('already exists in ClientComm')
        end

        context 'the user_confirmed value is true' do
          subject do
            post clients_path, params: {
              user_confirmed: true,
              client: {
                first_name: first_name,
                last_name: last_name,
                phone_number: phone_number,
                reporting_relationships_attributes: {
                  '0': {
                    user_id: user.id,
                    notes: notes,
                    client_status_id: client_status.id.to_s
                  }
                }
              }
            }
          end

          it 'creates the reporting relationship' do
            subject

            expect(response.code).to eq '302'
            expect(response).to redirect_to client_messages_path(client)

            rr = client.reporting_relationships.find_by(user: user)
            expect(rr.notes).to eq notes
            expect(rr.client_status).to eq client_status
          end
        end
      end
    end

    describe 'POST#update' do
      let(:first_name) { Faker::Name.first_name }
      let(:phone_number) { '+14663364863' }
      let(:notes) { Faker::Lorem.sentence }
      let(:last_name) { Faker::Name.last_name }
      let!(:existing_client) { create :client, user: user, created_at: 10.days.ago }

      subject do
        put client_path(existing_client), params: {
          client: {
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            reporting_relationships_attributes: {
              '0': {
                id: existing_client.reporting_relationships.find_by(user: user).id,
                notes: notes
              }
            }
          }
        }
      end

      it 'tracks the updating of a client' do
        create :message, user: user, client: existing_client, inbound: false
        create :message, user: user, client: existing_client, inbound: false, send_at: Time.now.tomorrow
        create :message, user: user, client: existing_client, inbound: true
        attachment_message = create :message, user: user, client: existing_client, inbound: true
        create :attachment, message: attachment_message
        existing_client.reporting_relationships.where(user: user).update(
          last_contacted_at: 5.days.ago,
          has_unread_messages: true
        )

        subject
        expect(response.code).to eq '302'
        expect(latest_analytics_event('client_edit_success')['hours_since_contact']).to be_within(1).of(120)
        expect_analytics_events({
                                  'client_edit_success' => {
                                    'client_id' => existing_client.id,
                                    'has_unread_messages' => true,
                                    'messages_all_count' => 4,
                                    'messages_received_count' => 2,
                                    'messages_sent_count' => 1,
                                    'messages_attachments_count' => 1,
                                    'messages_scheduled_count' => 1,
                                    'has_client_notes' => true
                                  }
                                })
      end

      it 'updates a client' do
        subject
        client = Client.last

        expect(response.code).to eq '302'
        expect(response).to redirect_to client_messages_path(client)

        expect(client.first_name).to eq first_name
        expect(client.last_name).to eq last_name
        expect(client.phone_number).to eq phone_number
        expect(client.reporting_relationships.find_by(user: user).notes).to eq notes
      end

      context 'a client has active users in multiple departments' do
        let(:user2) { create :user }
        let(:user3) { create :user }
        let(:user4) { create :user }

        before do
          existing_client.users << user2
          existing_client.users << user3
          existing_client.users << user4

          existing_client.reporting_relationships.find_by(user: user4)
                         .update(active: false)
        end

        it 'sends notification emails to other users' do
          mail = double('mail', deliver: true)
          expect(NotificationMailer).to receive(:client_edit_notification)
            .and_return(mail).twice
          expect(mail).to receive(:deliver_later).twice

          subject
        end
      end

      context 'receives invalid client parameters' do
        context 'receives empty last name' do
          let(:last_name) { nil }

          it 'renders edit with validation errors' do
            subject

            expect(flash[:alert]).to include 'There was a problem'
            expect(response.code).to eq '200'
            expect(response.body).to include "can't be blank"
          end
        end

        context 'receives invalid phone number' do
          let(:bad_number) { '(212) 55-5236' }
          let(:phone_number) { bad_number }

          it 'renders edit with invalid phone number validation error' do
            allow(SMSService.instance).to receive(:number_lookup)
              .with(phone_number: bad_number)
              .and_raise(SMSService::NumberNotFound)

            subject

            expect(flash[:alert]).to include 'There was a problem'
            expect(response.code).to eq '200'
            expect(response.body).to include 'not a valid phone number'
          end
        end
      end
    end

    describe 'GET#index' do
      let!(:another_client) { create :client }

      before do
        create_list :client, 5, user: user
      end

      subject { get clients_path }

      it 'tracks a visit to the client index with clients and messages' do
        create :message, user: user, client: user.clients.first, inbound: true
        create :message, user: user, client: user.clients.second, inbound: true
        create :message, user: user, client: user.clients.third, inbound: true

        subject

        expect(response.code).to eq '200'
        expect_analytics_events({
                                  'clients_view' => {
                                    'has_unread_messages' => true,
                                    'unread_messages_count' => 3,
                                    'clients_count' => 5
                                  }
                                })
      end

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
          archived_client.reporting_relationships.find_by(user: user).update!(active: false)
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
        end

        subject { get clients_path }

        context 'clients with active statuses require follow ups' do
          let(:active_contacted_at) { Time.now - 26.days }

          it 'shows active followup banner' do
            client = create :client
            ReportingRelationship.create(
              client: client,
              user: user,
              client_status: ClientStatus.find_by(name: 'Active'),
              last_contacted_at: active_contacted_at
            )

            subject

            expect(Nokogiri.parse(response.body).text)
              .to include('You have 1 active client due for follow up')
            expect(Nokogiri.parse(response.body).to_s)
              .to include('clients%5B%5D=' + client.id.to_s)
          end
        end
      end

      context 'there is a client with a conversation error' do
        let(:error_client) { user.clients.first }

        before do
          error_client.reporting_relationship(user: user).update!(has_message_error: true)
        end

        it 'shows a error logo' do
          subject

          expect(Nokogiri.parse(response.body).css("tr##{dom_id(error_client)} .icon-warning")).to be_present
        end
      end
    end

    describe 'GET#edit' do
      let(:client) { create :client, user: user, first_name: 'Fred', last_name: 'Flintstone' }

      subject { get edit_client_path(client) }

      it 'shows the current client data' do
        subject
        expect(response.body).to include(client.first_name)
        expect(response.body).to include(client.last_name)
      end

      it 'tracks a visit to the edit client form' do
        subject
        expect(response.code).to eq '200'
        expect_analytics_events_happened('client_edit_view')
      end

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

      context 'when the client belongs to more than one active user' do
        let(:other_user) { create :user, full_name: 'Jerry Mouse' }

        before do
          client.users << other_user
        end

        it 'shows a relevant notification' do
          subject

          expect(response.body).to include(other_user.full_name)
          expect(response.body).to include("Changing the client's name or phone number will change it for everyone.")
        end
      end
    end
  end
end
