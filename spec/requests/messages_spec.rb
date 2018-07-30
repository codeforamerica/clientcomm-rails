require 'rails_helper'

describe 'Messages requests', type: :request, active_job: true do
  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      user = create :user
      client = create :client, user: user

      rr = user.reporting_relationships.find_by(client: client)
      get reporting_relationship_path(rr)

      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'authenticated' do
    let(:department) { create :department }
    let(:user) { create :user, department: department }
    let(:client) { create :client, user: user }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let(:body) { 'hello, my friend' }

    before do
      sign_in user
    end

    describe 'DELETE#destroy' do
      context 'there are scheduled messages' do
        it 'deletes a scheduled message' do
          message = create :text_message, reporting_relationship: rr, send_at: Time.zone.now.tomorrow

          delete message_path(message)

          expect(response.code).to eq '302'
          rr = user.reporting_relationships.find_by(client: client)
          expect(response).to redirect_to reporting_relationship_path(rr)

          rr = user.reporting_relationships.find_by(client: client)
          get reporting_relationship_path(rr)
          expect(response.body).to_not include('1 message scheduled')

          expect_analytics_events_happened('message_scheduled_delete')
        end
      end
    end

    describe 'GET#edit' do
      it 'renders the requested message template' do
        message = create :text_message, reporting_relationship: rr, inbound: true, send_at: Time.zone.local(2018, 07, 11, 20, 30, 0)

        get edit_message_path(message)

        expect(response.body).to include(message.body)
        expect(response.body).to include('07/11/2018')

        expect_analytics_events_happened('message_scheduled_edit_view')
      end
    end

    describe 'POST#create' do
      let(:post_params) do
        {
          message: { body: body, send_at: message_send_at },
          client_id: client.id
        }
      end

      context 'no date' do
        let(:message_send_at) { nil }

        it 'creates a new message on submit' do
          post messages_path, params: post_params

          message = Message.find_by(body: body)

          expect(ScheduledMessageJob).to have_been_enqueued
          created_message = client.messages.last

          expect(created_message.id).to eq message.id
          expect(created_message.read).to eq true
          expect(created_message.send_at).to_not be_nil
          expect(created_message.number_from).to eq department.phone_number

          expect_most_recent_analytics_event(
            'message_send' => {
              'client_id' => client.id,
              'message_id' => message.id,
              'message_length' => body.length,
              'positive_template' => false,
              'positive_template_type' => nil
            }
          )
        end
      end

      context 'had positive_template_type' do
        let(:positive_template) { 'some positive template' }
        let(:post_params) do
          {
            message: { body: body, send_at: message_send_at },
            client_id: client.id,
            positive_template_type: positive_template
          }
        end
        let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
        let(:likeable_message) { create :text_message, reporting_relationship: rr }
        let(:message_send_at) { nil }

        it 'creates a new message on submit' do
          post messages_path, params: post_params

          message = Message.find_by(body: body)

          expect_most_recent_analytics_event(
            'message_send' => {
              'client_id' => client.id,
              'message_id' => message.id,
              'message_length' => body.length,
              'positive_template' => true,
              'positive_template_type' => positive_template
            }
          )
        end
      end

      context 'invalid date' do
        let(:message_send_at) {
          {
            date: '2011/02/',
            time: '9:30pm'
          }
        }

        it 'does not create a new message' do
          allow(DateParser).to receive(:parse)
            .with(message_send_at[:date], message_send_at[:time])
            .and_return(nil)

          post messages_path, params: post_params

          expect(ScheduledMessageJob).not_to have_been_enqueued
          response_body = Nokogiri::HTML(response.body).to_s
          expect(response_body).to include "That date didn't look right."
          expect(response_body).to include body
        end
      end

      context 'past date' do
        let(:time_in_past) { Time.zone.now.yesterday.change(sec: 0) }
        let(:message_send_at) {
          {
            date: time_in_past.strftime('%m/%d/%Y'),
            time: time_in_past.strftime('%-l:%M%P')
          }
        }

        it 'does not create a new message' do
          allow(DateParser).to receive(:parse)
            .with(message_send_at[:date], message_send_at[:time])
            .and_return(time_in_past)

          post messages_path, params: post_params

          expect(ScheduledMessageJob).not_to have_been_enqueued
          response_body = Nokogiri::HTML(response.body).to_s
          expect(response_body).to include "You can't schedule a message in the past."
          expect(response_body).to include body
          expect(response_body).to include time_in_past.strftime('%m/%d/%Y')
        end
      end

      context 'valid date' do
        let(:time_to_send) { Time.zone.now.tomorrow.change(sec: 0) }
        let(:message_send_at) {
          {
            date: time_to_send.strftime('%m/%d/%Y'),
            time: time_to_send.strftime('%-l:%M%P')
          }
        }

        it 'creates a Scheduled Message' do
          allow(DateParser).to receive(:parse)
            .with(message_send_at[:date], message_send_at[:time])
            .and_return(time_to_send)

          post messages_path, params: post_params

          message = Message.find_by(body: body)

          expect(ScheduledMessageJob).to have_been_enqueued.at(time_to_send)
          expect(flash[:notice]).to eq('Your message has been scheduled')

          expect(client.messages.last.id).to eq message.id
          expect_analytics_events_with_keys(
            'message_scheduled' => [
              'client_id',
              'message_id',
              'message_length',
              'message_date_scheduled',
              'message_date_created'
            ]
          )
        end
      end
    end

    describe 'PUT#update' do
      let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
      let!(:message) { create(:text_message, reporting_relationship: rr, body: body, send_at: Time.zone.now.tomorrow.change(sec: 0)) }
      let(:post_params) {
        {
          message: { body: new_body, send_at: message_send_at }
        }
      }
      let(:new_body) { 'Some new body' }

      context 'valid update' do
        let(:message_send_at) { { date: 'some_date', time: 'some_time' } }

        it 'updates the message model' do
          new_time_to_send = Time.zone.now.change(sec: 0)
          allow(DateParser).to receive(:parse)
            .with(message_send_at[:date], message_send_at[:time])
            .and_return(new_time_to_send)

          old_message_id = Message.find_by(body: body).id

          put message_path(message), params: post_params

          expect(ScheduledMessageJob).to have_been_enqueued.at(new_time_to_send)

          new_message = Message.find(old_message_id)
          expect(new_message.body).to eq(new_body)
          expect(new_message.send_at).to eq(new_time_to_send)
        end
      end

      context 'invalid update' do
        let(:time_in_past) { Time.zone.now.yesterday.change(sec: 0) }
        let(:message_send_at) {
          {
            date: time_in_past.strftime('%m/%d/%Y'),
            time: time_in_past.strftime('%-l:%M%P')
          }
        }

        it 'fails if date is invalid' do
          allow(DateParser).to receive(:parse)
            .with(message_send_at[:date], message_send_at[:time])
            .and_return(nil)

          put message_path(message), params: post_params
          expect(ScheduledMessageJob).to_not have_been_enqueued
          response_body = Nokogiri::HTML(response.body).to_s
          expect(response_body).to include "That date didn't look right."
          expect(response_body).to include new_body
        end

        it 'fails if date is in the past' do
          allow(DateParser).to receive(:parse)
            .with(message_send_at[:date], message_send_at[:time])
            .and_return(time_in_past)

          put message_path(message), params: post_params
          expect(ScheduledMessageJob).to_not have_been_enqueued
          response_body = Nokogiri::HTML(response.body).to_s
          expect(response_body).to include "You can't schedule a message in the past."
          expect(response_body).to include new_body
          expect(response_body).to include time_in_past.strftime('%m/%d/%Y')
        end
      end
    end

    describe 'GET#download' do
      it 'downloads messages as a text file' do
        messages = create_list :text_message, 10, reporting_relationship: rr

        rr = user.reporting_relationships.find_by(client: client)
        get reporting_relationship_messages_download_path(rr)

        messages.each do |message|
          transcript_status = %w[undelivered failed].include?(message.twilio_status) ? 'NOT DELIVERED' : message.twilio_status

          expect(response.body).to include(message.number_from) if message.inbound
          expect(response.body).to include(message.number_to) unless message.inbound
          expect(response.body).to include(message.send_at.strftime('%b %-d %Y, %-l:%M:%S %P'))
          expect(response.body).to include(message.body)
          expect(response.body).to include(transcript_status)
          expect(response.body).to include(client.first_name)
          expect(response.body).to include(user.full_name)
        end
      end

      it 'orders downloaded messages by send_at' do
        msgs_count = 10
        messages = create_list :text_message, msgs_count, reporting_relationship: rr
        messages.each_with_index do |message, i|
          message.update(
            created_at: message.created_at - (msgs_count - i).hours,
            send_at: message.send_at - i.hours
          )
        end
        rr = user.reporting_relationships.find_by(client: client)
        get reporting_relationship_messages_download_path(rr)
        messages.each_with_index do |message, i|
          if i < msgs_count - 1
            expect(response.body.index(message.body)).to be > response.body.index(messages[i + 1].body)
          end
        end
      end

      context 'the user has transfer markers' do
        it 'displays the transfer marker' do
          marker = create :transfer_marker, reporting_relationship: rr
          rr = user.reporting_relationships.find_by(client: client)
          get reporting_relationship_messages_download_path(rr)

          expect(response.body).to include("-- #{marker.body} --")
        end
      end

      context 'the user has client edit markers' do
        it 'displays the client edit marker' do
          marker = create :client_edit_marker, reporting_relationship: rr
          rr = user.reporting_relationships.find_by(client: client)
          get reporting_relationship_messages_download_path(rr)

          expect(response.body).to include("-- #{marker.body} --")
        end
      end

      context 'a message has an undelivered error' do
        let(:rr) { user.reporting_relationships.find_by(client: client) }

        before do
          create :text_message, inbound: false, reporting_relationship: rr, twilio_status: 'undelivered'
        end

        it 'displays the issue prominently' do
          get reporting_relationship_messages_download_path(rr)

          expect(response.body).to include('UNDELIVERED')
          expect(response.body).to include('NOT DELIVERED to cell')
          error_text = I18n.t('message.status.undelivered')
          expect(response.body).to include("ERROR: #{error_text}")
        end
      end

      context 'a message has an blacklisted error' do
        let(:rr) { user.reporting_relationships.find_by(client: client) }

        before do
          create :text_message, inbound: false, reporting_relationship: rr, twilio_status: 'blacklisted'
        end

        it 'displays the issue prominently' do
          get reporting_relationship_messages_download_path(rr)

          expect(response.body).to include('UNDELIVERED')
          expect(response.body).to include('NOT DELIVERED to cell')
          error_text = I18n.t('message.status.blacklisted')
          expect(response.body).to include("ERROR: #{error_text}")
        end
      end

      context 'a message has a nil status' do
        let(:rr) { user.reporting_relationships.find_by(client: client) }

        before do
          create :text_message, inbound: false, reporting_relationship: rr, twilio_status: nil
        end

        it 'displays the issue prominently' do
          get reporting_relationship_messages_download_path(rr)

          expect(response.body).to include('UNDELIVERED')
          expect(response.body).to include('NOT DELIVERED to cell')
          expect(response.body).to include('ERROR: Message could not be')
        end
      end
    end
  end
end
