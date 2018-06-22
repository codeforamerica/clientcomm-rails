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
      let(:client) { create :client, user: user, first_name: 'FirstName', last_name: 'LastName' }
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
      let(:future_date) { Time.zone.now.change(min: 0, day: 3) + 1.month }
      let(:future_date_formatted) { future_date.strftime('%m/%d/%Y') }
      let!(:client_status) { create :client_status }

      subject do
        post clients_path, params: {
          client: {
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            next_court_date_at: future_date_formatted,
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
        rr = user.reporting_relationships.find_by(client: Client.last)
        expect(response).to redirect_to reporting_relationship_path(rr)
        expect(Client.count).to eq 1

        client = Client.first
        rr = client.reporting_relationships.find_by(user: user)
        expect(client.users).to include user
        expect(client.first_name).to eq first_name
        expect(client.last_name).to eq last_name
        expect(client.phone_number).to eq phone_number
        expect(rr.notes).to eq notes
        expect(rr.client_status).to eq client_status
        expect(client.next_court_date_at).to eq future_date.to_date
      end

      it 'tracks the creation of a new client' do
        subject

        client = Client.first

        expect_analytics_events(
          'client_create_success' => {
            'client_id' => client.id,
            'has_court_date' => true
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
            expect_analytics_events(
              'client_create_error' => {
                'error_types' => ['last_name_blank']
              }
            )
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
            expect_analytics_events(
              'client_create_error' => {
                'error_types' => ['phone_number_invalid']
              }
            )
          end
        end

        context 'multiple columns have validation failures' do
          let(:bad_number) { '(212) 55-5236' }
          let(:phone_number) { bad_number }
          let(:last_name) { nil }
          before do
            allow(SMSService.instance).to receive(:number_lookup)
              .with(phone_number: bad_number)
              .and_raise(SMSService::NumberNotFound)
          end

          it 'tracks all validation errors' do
            subject

            event = latest_analytics_event 'client_create_error'
            expect(event['error_types']).to include('last_name_blank', 'phone_number_invalid')
          end
        end
      end

      context 'client has a relationship with a user in the same department' do
        context 'client already exists under this user' do
          let!(:client) { create :client, first_name: 'Yaco', last_name: 'Romero', user: user, phone_number: phone_number }
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
            rr = user.reporting_relationships.find_by(client: client)
            expect(response).to redirect_to reporting_relationship_path(rr)
            expect(flash[:notice]).to eq 'You already have a client with this phone number.'
          end

          context 'client has an inactive relationship in this department' do
            let(:conflicting_user) { create :user, department: user.department }

            before do
              ReportingRelationship.create(user: conflicting_user, client: client, active: false)
            end

            it 'redirects to the messages page' do
              allow(SMSService.instance).to receive(:number_lookup)
                .with(phone_number: abnormal_number)
                .and_return(phone_number)

              subject

              expect(response.code).to eq '302'
              rr = user.reporting_relationships.find_by(client: client)
              expect(response).to redirect_to reporting_relationship_path(rr)
              expect(flash[:notice]).to eq 'You already have a client with this phone number.'
            end
          end

          context 'client has a prior, inactive, relationship with this user' do
            let!(:client) { create :client, first_name: 'Sandro', last_name: 'Adame', user: user, phone_number: phone_number, active: false }

            it 'redirects to the messages page' do
              allow(SMSService.instance).to receive(:number_lookup)
                .with(phone_number: abnormal_number)
                .and_return(phone_number)

              subject

              expect(response.code).to eq '302'
              rr = user.reporting_relationships.find_by(client: client)
              expect(response).to redirect_to reporting_relationship_path(rr)
              expect(client.reporting_relationships.find_by(user: user)).to be_active
            end
          end
        end

        context 'client has a relationship with a different user in the same department' do
          let(:other_user) { create :user, department: user.department }
          let!(:client) { create :client, first_name: 'Archer', last_name: 'Cadena', user: other_user, phone_number: phone_number }

          it 'shows an error flash' do
            subject

            expect(response.code).to eq '200'
            expect(flash[:alert]).to include 'There was a problem saving this client.'
            expect(response.body).to include I18n.t(
              'activerecord.errors.models.reporting_relationship.attributes.client.existing_dept_relationship',
              user_full_name: other_user.full_name
            )
            expect(response.body).to_not include I18n.t 'activerecord.errors.models.client.attributes.phone_number.taken'
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
            rr = user.reporting_relationships.find_by(client: client)
            expect(response).to redirect_to reporting_relationship_path(rr)

            rr = client.reporting_relationships.find_by(user: user)
            expect(rr.notes).to eq notes
            expect(rr.client_status).to eq client_status
          end
        end
      end
    end

    describe 'PUT#update' do
      let(:first_name) { 'Szepesi' }
      let(:last_name) { 'Erzebet' }
      let(:phone_number) { '+14663364863' }
      let(:id_number) { '1234' }
      let(:notes) { Faker::Lorem.sentence }
      let(:future_date) { Time.zone.now.change(min: 0, day: 3) + 1.month }
      let(:future_date_formatted) { future_date.strftime('%m/%d/%Y') }
      let!(:existing_client) { create :client, first_name: 'Laszlo', last_name: 'Robledo', user: user, created_at: 10.days.ago }

      subject do
        put client_path(existing_client), params: {
          client: {
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            id_number: id_number,
            next_court_date_at: future_date_formatted,
            reporting_relationships_attributes: {
              '0': {
                id: existing_client.reporting_relationships.find_by(user: user).id,
                notes: notes
              }
            }
          }
        }
      end

      context 'deactivating a client' do
        let!(:survey_question) { create :survey_question }
        let!(:survey_response1) { create :survey_response, survey_question: survey_question, text: 'Successful closeout' }
        let!(:survey_response2) { create :survey_response, survey_question: survey_question, text: 'FTA' }
        let!(:survey_response3) { create :survey_response, survey_question: survey_question, text: 'Supervision rescinded' }

        before do
          existing_client.reporting_relationship(user: user).update(created_at: 10.days.ago)
        end

        subject do
          put client_path(existing_client), params: {
            client: {
              reporting_relationships_attributes: {
                '0': {
                  id: existing_client.reporting_relationships.find_by(user: user).id,
                  active: false
                }
              },
              surveys_attributes: {
                '0': {
                  survey_response_ids: [survey_response1.id, survey_response2.id, survey_response3.id]
                }
              }
            }
          }
        end

        it 'deactivates the rr' do
          subject
          expect(existing_client.active(user: user))
            .to eq(false)
        end

        it 'creates a survey' do
          subject
          expect(Survey.count).to eq(1)
          expect(Survey.last.survey_responses.count).to eq(3)
          expect(Survey.last.survey_responses).to include(survey_response1, survey_response2, survey_response3)
        end

        it 'attaches the survey to the right user and client' do
          subject
          expect(Survey.last.client).to eq(existing_client)
          expect(Survey.last.user).to eq(user)
        end

        it 'tracks the deactivation of a client' do
          subject
          expect_analytics_events(
            'client_deactivate_success' => {
              'client_id' => existing_client.id,
              'client_duration' => 10
            }
          )
        end

        context 'has scheduled messages' do
          let(:rr) { existing_client.reporting_relationships.find_by(user: user) }
          before do
            create :text_message, reporting_relationship: rr, send_at: Time.zone.now + 1.day
          end

          it 'deletes scheduled messages' do
            subject
            expect(rr.messages.scheduled).to be_empty
          end
        end
      end

      it 'tracks the updating of a client' do
        rr = ReportingRelationship.find_by(user: user, client: existing_client)
        create :text_message, reporting_relationship: rr, inbound: false
        create :text_message, reporting_relationship: rr, inbound: false, send_at: Time.zone.now.tomorrow
        create :text_message, reporting_relationship: rr, inbound: true
        attachment_message = create :text_message, reporting_relationship: rr, inbound: true
        create :attachment, message: attachment_message
        existing_client.reporting_relationships.where(user: user).update(
          last_contacted_at: 5.days.ago,
          has_unread_messages: true
        )

        subject
        expect(response.code).to eq '302'
        expect(latest_analytics_event('client_edit_success')['hours_since_contact']).to be_within(1).of(120)
        expect_analytics_events('client_edit_success' => {
                                  'client_id' => existing_client.id,
                                  'has_unread_messages' => true,
                                  'messages_all_count' => 4,
                                  'messages_received_count' => 2,
                                  'messages_sent_count' => 1,
                                  'messages_attachments_count' => 1,
                                  'messages_scheduled_count' => 1,
                                  'has_client_notes' => true,
                                  'has_court_date' => true
                                })
      end

      it 'updates a client' do
        subject
        client = Client.last

        expect(response.code).to eq '302'
        rr = user.reporting_relationships.find_by(client: client)
        expect(response).to redirect_to reporting_relationship_path(rr)

        expect(client.first_name).to eq first_name
        expect(client.last_name).to eq last_name
        expect(client.phone_number).to eq phone_number
        expect(client.reporting_relationships.find_by(user: user).notes).to eq notes
        expect(client.id_number).to eq id_number
        expect(client.next_court_date_at).to eq future_date.to_date
      end

      context 'user sets next court date' do
        before do
          existing_client.update!(next_court_date_set_by_user: false)
        end

        it 'marks court date set by client to true' do
          subject

          expect(existing_client.reload.next_court_date_set_by_user).to be true
        end
      end

      context 'a court date was already set' do
        before do
          existing_client.update(next_court_date_at: future_date)
        end

        it 'does not set the flag' do
          subject

          expect(existing_client.reload.next_court_date_set_by_user).to be false
        end
      end

      context 'user clears next court date' do
        let(:future_date_formatted) { '' }

        before do
          existing_client.update!(next_court_date_set_by_user: true)
        end

        it 'marks court date set by client to false' do
          subject

          expect(existing_client.reload.next_court_date_set_by_user).to be false
        end
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

        context 'neither phone number nor name were changed' do
          subject do
            put client_path(existing_client), params: {
              client: {
                first_name: existing_client.first_name,
                last_name: existing_client.last_name,
                phone_number: existing_client.phone_number,
                reporting_relationships_attributes: {
                  '0': {
                    id: existing_client.reporting_relationships.find_by(user: user).id,
                    notes: notes
                  }
                }
              }
            }
          end

          it 'logs that name and phone number did not change' do
            allow(Rails.logger).to receive(:warn)
            expect(Rails.logger).to receive(:warn).with('Phone number and name did not change.')
            perform_enqueued_jobs do
              subject
            end
          end
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
            event = latest_analytics_event 'client_edit_error'
            expect(event['error_types']).to include('last_name_blank')
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

        context 'conflicting edits with existing client records' do
          context 'phone_number' do
            context 'the existing client has a same-department relationship' do
              let(:other_user) { create :user, department: user.department }
              let(:other_client) { create :client, first_name: 'Raquildis', last_name: 'Cordero', user: other_user }
              let(:phone_number) { other_client.phone_number }

              it 'shows an error flash and validation note on the form' do
                subject

                validation_error = I18n.t(
                  'activerecord.errors.models.reporting_relationship.attributes.client.existing_dept_relationship',
                  user_full_name: other_user.full_name
                )
                expect(response.code).to eq '200'
                expect(flash[:alert]).to include 'There was a problem saving this client.'
                expect(response.body).to include validation_error
                expect(response.body).to include other_user.full_name
                expect(response.body).to_not include I18n.t 'activerecord.errors.models.client.attributes.phone_number.taken'
              end

              context 'the user has an existing client with the same phone number and an inactive same-department relationship with another user' do
                before do
                  ReportingRelationship.find_by(user: other_user, client: other_client).update!(active: false)
                  other_client.users << user
                end

                it 'shows an error flash and validation note on the form' do
                  subject

                  expect(response.code).to eq '200'
                  expect(flash[:alert]).to include 'There was a problem saving this client.'

                  dept_validation_error = I18n.t(
                    'activerecord.errors.models.reporting_relationship.attributes.client.existing_dept_relationship',
                    user_full_name: other_user.full_name
                  )
                  expect(response.body).to_not include I18n.t 'activerecord.errors.models.client.attributes.phone_number.taken'
                  expect(response.body).to_not include dept_validation_error

                  other_rr = other_client.reporting_relationships.find_by(user: user)
                  user_validation_error = I18n.t(
                    'activerecord.errors.models.reporting_relationship.attributes.client.existing_user_relationship',
                    client_full_name: "#{other_client.first_name} #{other_client.last_name}",
                    href: reporting_relationship_url(other_rr)
                  )
                  expect(response.body).to include user_validation_error
                end
              end

              context 'multiple reporting relationships' do
                let(:external_user) { create :user }

                before do
                  existing_client.users << external_user
                end

                it 'does not display multiple reporting relationships' do
                  subject

                  expect(response.body.scan(/private note/).count).to eq 1
                end
              end
            end
          end
        end
      end
    end

    describe 'GET#index' do
      let!(:another_client) { create :client, first_name: 'Angelines', last_name: 'Luevano' }

      before do
        create :client, first_name: 'Vespasiano', last_name: 'Laureano', user: user
        create :client, first_name: 'Mirta', last_name: 'Prieto', user: user
        create :client, first_name: 'Liberto', last_name: 'Jiminez', user: user, next_court_date_at: Time.current + 1.day
        create :client, first_name: 'Peregrino', last_name: 'Pena', user: user, next_court_date_at: Time.current + 1.day
        create :client, first_name: 'Baldo', last_name: 'Godoy', user: user, next_court_date_at: Time.current + 1.day
      end

      subject { get clients_path }

      it 'tracks a visit to the client index with clients and messages' do
        rr1 = ReportingRelationship.find_by(user: user, client: user.clients.first)
        create :text_message, reporting_relationship: rr1, inbound: true

        rr2 = ReportingRelationship.find_by(user: user, client: user.clients.second)
        rr2.update(category: 'cat1')
        create :text_message, reporting_relationship: rr2, inbound: true

        rr3 = ReportingRelationship.find_by(user: user, client: user.clients.third)
        rr3.update(category: 'cat1')
        create :text_message, reporting_relationship: rr3, inbound: true

        subject

        expect(response.code).to eq '200'
        expect_analytics_events('clients_view' => {
                                  'has_unread_messages' => true,
                                  'unread_messages_count' => 3,
                                  'clients_count' => 5,
                                  'symbols_count' => 2,
                                  'court_dates_count' => 3
                                })
      end

      it 'returns a list of clients' do
        subject

        user.clients.each do |client|
          expect(response.body).to include("#{client.first_name} #{client.last_name}")
        end

        expect(response.body).not_to include("#{another_client.first_name} #{another_client.last_name}")
      end

      context 'the user is in the 1-4 treatment group' do
        it 'displays a tips and tricks prompt' do
          subject
          expect(response.body).to_not include(I18n.t('views.tips.positive_reinforcement_html'))

          user.update!(treatment_group: 'ebp-1-4')
          get clients_path
          expect(response.body).to include(I18n.t('views.tips.positive_reinforcement_html'))
        end
      end

      context 'there are deactivated clients' do
        let(:deactivated_client) { user.clients.first }

        before do
          deactivated_client.reporting_relationships.find_by(user: user).update!(active: false)
        end

        it 'does not return deactivated clients' do
          subject

          expect(response.body).to_not include("#{deactivated_client.first_name} #{deactivated_client.last_name}")
        end
      end

      context 'client status enabled' do
        before do
          @client_status = create :client_status, name: 'Active', followup_date: 30, icon_color: '#333333', department: user.department
        end

        subject { get clients_path }

        context 'clients with active statuses require follow ups' do
          let(:active_contacted_at) { Time.zone.now - 26.days }

          it 'shows active followup banner' do
            client = create :client, first_name: 'Celest', last_name: 'Maldonado'
            rr = ReportingRelationship.create(
              client: client,
              user: user,
              client_status: @client_status,
              last_contacted_at: active_contacted_at
            )

            subject
            page = Nokogiri.parse(response.body)
            expect(page.text)
              .to include('You have 1 active client due for follow up')
            expect(response.body)
              .to include('reporting_relationships%5B%5D=' + rr.id.to_s)
            icon = page.css('i.status-icon').to_s
            expect(icon).to include('style="background-color:#333333"')
          end
          it 'shows status color' do
            client = create :client, first_name: 'Cibeles', last_name: 'Verdugo'
            ReportingRelationship.create(
              client: client,
              user: user,
              client_status: @client_status,
              last_contacted_at: active_contacted_at
            )

            subject
            page = Nokogiri.parse(response.body)
            icon = page.css('i.status-icon').to_s
            expect(icon).to include('style="background-color:#333333"')
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
      let(:survey_question_text) { 'What was the outcome for this client?' }
      let(:survey_response_text) { 'FTA' }

      before do
        q = create :survey_question, text: survey_question_text
        create :survey_response, survey_question: q, text: survey_response_text
      end

      subject { get edit_client_path(client) }

      it 'shows the current client data' do
        subject
        expect(response.body).to include(client.first_name)
        expect(response.body).to include(client.last_name)
      end

      it 'tracks a visit to the edit client form' do
        subject
        expect(response.code).to eq '200'
        expect_analytics_events(
          'client_edit_view' => {
            'client_id' => client.id
          }
        )
      end

      context 'the client has a court date' do
        let(:client) { create :client, user: user, first_name: 'Fred', last_name: 'Flintstone', next_court_date_at: Time.current + 1.day }

        it 'tracks a visit to the edit client form' do
          subject
          expect(response.code).to eq '200'
          expect_analytics_events(
            'client_edit_view' => {
              'client_id' => client.id,
              'has_court_date' => true
            }
          )
        end
      end

      it 'renders a closeout survey' do
        subject
        expect(response.code).to eq '200'
        expect(response.body).to include(survey_question_text)
        expect(response.body).to include(survey_response_text)
      end

      context 'has client statuses' do
        let!(:status) { create :client_status, department: user.department }
        before do
          create :client_status
        end
        it 'does not display inactive users in transfer dropdown' do
          subject
          radio_buttons = Nokogiri.parse(response.body).css('label.radio-button')
          expect(radio_buttons.length).to eq(1)
          expect(radio_buttons.first.text).to include(status.name)
        end
      end

      context 'has inactivate users' do
        let(:full_name_inactive) { 'My Name' }
        let(:full_name_active) { 'Not Same' }
        before do
          create :user, department: user.department, full_name: full_name_active
          create :user, department: user.department, active: false, full_name: full_name_inactive
        end

        it 'does not display inactive users in transfer dropdown' do
          subject
          options = Nokogiri.parse(response.body).css('#new_reporting_relationship select option').map(&:text)
          expect(options).to include(full_name_active)
          expect(options).to_not include(full_name_inactive)
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
