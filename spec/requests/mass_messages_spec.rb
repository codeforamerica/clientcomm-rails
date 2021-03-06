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
    let(:rr_1) { ReportingRelationship.find_by(user: user, client: client_1)  }
    let(:rr_2) { ReportingRelationship.find_by(user: user, client: client_2)  }
    let(:rr_3) { ReportingRelationship.find_by(user: user, client: client_3)  }
    let(:message_body) { 'hello this is message one' }
    let(:rrs) { ['', rr_1.id, rr_3.id] }

    subject do
      post mass_messages_path, params: {
        mass_message: {
          message: message_body,
          reporting_relationships: rrs
        }
      }
    end

    it 'sends message to multiple rrs' do
      perform_enqueued_jobs { subject }

      expect(user.messages.count).to eq 2
      expect(client_1.messages.count).to eq 1
      expect(client_1.messages.first.body).to eq message_body
      expect(client_1.messages.first.number_from).to eq department.phone_number
      expect(client_2.messages.count).to eq 0
      expect(client_3.messages.count).to eq 1
      expect(client_3.messages.first.body).to eq message_body
      expect(client_3.messages.first.number_from).to eq department.phone_number
    end

    it 'sends a single mass_message_send event with recipient_count' do
      subject
      expect_analytics_events(
        'mass_message_send' => {
          'recipients_count' => 2
        }
      )
    end

    context 'has categories set' do
      before do
        FeatureFlag.create!(flag: 'categories', enabled: true)
        rr_1.update!(category: 'cat1')
      end
      it 'shows the proper icons' do
        get new_mass_message_path
        expect(response.body).to include 'icon-icon1'
        expect(response.body).to include 'data-category-order="1"'
      end
    end

    context 'no message body inputted' do
      let(:message_body) { '' }

      it 're-renders the page with errors' do
        subject
        expect(response.body).to include 'You need to add a message.'
      end
    end

    context 'no message recipients selected' do
      let(:message_body) { '' }
      let(:rrs) { [''] }

      it 're-renders the page with errors' do
        subject
        expect(response.body).to include 'You need to pick at least one recipient.'
      end
    end

    context 'a send_at date is set' do
      let(:send_at) { Time.zone.now.change(sec: 0, usec: 0) + 2.days }

      subject do
        post mass_messages_path, params: {
          commit: 'Schedule messages',
          mass_message: {
            message: message_body,
            reporting_relationships: rrs,
            send_at: {
              date: send_at.strftime('%m/%d/%Y'),
              time: send_at.strftime('%-l:%M%P')
            }
          }
        }
      end

      it 'sends message to multiple rrs at the right time' do
        perform_enqueued_jobs { subject }

        expect(client_1.messages.first.send_at).to eq send_at
        expect(client_3.messages.first.send_at).to eq send_at
      end

      context 'the scheduled commit is not present' do
        let(:now) { Time.zone.now.change(usec: 0) }

        subject do
          post mass_messages_path, params: {
            mass_message: {
              message: message_body,
              reporting_relationships: rrs,
              send_at: {
                date: send_at.strftime('%m/%d/%Y'),
                time: send_at.strftime('%-l:%M%P')
              }
            }
          }
        end

        it 'sends message to multiple rrs immediately' do
          travel_to now do
            perform_enqueued_jobs { subject }
          end

          expect(client_1.messages.first.send_at).to eq now
          expect(client_3.messages.first.send_at).to eq now
        end
      end

      it 'sends a single mass_message_send event with recipient_count' do
        subject
        expect_analytics_events(
          'mass_message_scheduled' => {
            'recipients_count' => 2
          }
        )
      end

      context 'the date is in the past' do
        let(:send_at) { Time.zone.now.change(sec: 0, usec: 0) - 2.days }

        it 'renders an error' do
          subject

          # do not use I18n because the single-quote gets rendered wrong in the body
          expect(response.body).to include('in the past')
        end
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

    context 'using a url to pre-populate body' do
      let(:params) { { message: 'this is the body' } }

      it 'renders checkboxes selected correctly' do
        subject

        expect(response.body).to include('this is the body</textarea>')
      end
    end

    context 'using a url to pre-populate rrs' do
      let(:params) { { reporting_relationships: [user.reporting_relationships[0].id, user.reporting_relationships[2].id] } }

      it 'renders checkboxes selected correctly' do
        subject

        rrs = user.reporting_relationships

        expect(response.body).to include("value=\"#{rrs[0].id}\" checked=\"checked\"")
        expect(response.body).to include("value=\"#{rrs[2].id}\" checked=\"checked\"")
        expect(response.body).to include("value=\"#{rrs[1].id}\" name")
      end
    end

    context 'client status feature flag enabled' do
      let(:status) { create :client_status, department: department }

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
