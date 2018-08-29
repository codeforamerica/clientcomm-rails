require 'rails_helper'

describe 'Messages requests', type: :request, active_job: true do
  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      user = create :user
      client = create :client, user: user

      get reporting_relationship_path(user.reporting_relationships.find_by(client: client))

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
          expect(response).to redirect_to reporting_relationship_path(rr)

          get reporting_relationship_path(rr)
          expect(response.body).to_not include('1 message scheduled')

          expect_analytics_events_happened('message_scheduled_delete')
        end
      end
    end

    describe 'GET#show' do
      context 'a user has sent messages' do
        let(:rr) { user.reporting_relationships.find_by(client: client) }

        before do
          create :text_message, inbound: false, reporting_relationship: rr, twilio_status: nil
          create :text_message, inbound: false, reporting_relationship: rr, twilio_status: 'sent'
          create :text_message, inbound: false, reporting_relationship: rr, twilio_status: 'sending'
        end

        it 'marks sent, nil, and sending as Sending' do
          get reporting_relationship_path(rr)

          expect(response.body.scan(I18n.t('message.status.sent')).size).to eq(3)
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
              'positive_template_type' => nil,
              'attachment' => false
            }
          )
        end

        context 'an image is attached' do
          let(:image) { fixture_file_upload('spec/fixtures/fluffy_cat.jpg', 'image/jpg') }
          let(:post_params) do
            {
              message: {
                body: body,
                send_at: message_send_at,
                attachments: [{ media: image }]
              },
              client_id: client.id
            }
          end
          subject do
            post messages_path, params: post_params
          end
          it 'creates a new message on submit' do
            subject
            message = Message.find_by(body: body)
            expect(message.attachments.count).to eq(1)
            expect(message.attachments.first.media_file_name).to eq('fluffy_cat.jpg')
            expect(message.attachments.first.media_content_type).to eq('image/jpeg')
            expect_most_recent_analytics_event(
              'message_send' => {
                'client_id' => client.id,
                'message_id' => message.id,
                'message_length' => body.length,
                'positive_template' => false,
                'positive_template_type' => nil,
                'attachment' => true
              }
            )
          end

          context 'image is too large' do
            let(:image) { fixture_file_upload('spec/fixtures/large_image.jpg', 'image/jpg') }

            it 'not to create message' do
              perform_enqueued_jobs do
                subject
              end
              expect(Message.all).to be_empty
            end
          end
          context 'is not an image' do
            let(:image) { fixture_file_upload('spec/fixtures/cat_contact.vcf', 'image/jpg') }

            it 'not to create message' do
              perform_enqueued_jobs do
                subject
              end
              expect(Message.all).to be_empty
            end
          end
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

          expect(ScheduledMessageJob).to have_been_enqueued.with(message: message)
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

      subject { put message_path(message), params: post_params }

      context 'valid update' do
        let(:message_send_at) { { date: 'some_date', time: 'some_time' } }

        it 'updates the message model' do
          new_time_to_send = Time.zone.now.change(sec: 0)
          allow(DateParser).to receive(:parse)
            .with(message_send_at[:date], message_send_at[:time])
            .and_return(new_time_to_send)

          old_message_id = Message.find_by(body: body).id

          subject

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

          subject

          response_body = Nokogiri::HTML(response.body).to_s
          expect(response_body).to include "That date didn't look right."
          expect(response_body).to include new_body
        end

        it 'fails if date is in the past' do
          allow(DateParser).to receive(:parse)
            .with(message_send_at[:date], message_send_at[:time])
            .and_return(time_in_past)

          subject

          response_body = Nokogiri::HTML(response.body).to_s
          expect(response_body).to include "You can't schedule a message in the past."
          expect(response_body).to include new_body
          expect(response_body).to include time_in_past.strftime('%m/%d/%Y')
        end
      end
    end

    describe 'GET#download' do
      subject { get reporting_relationship_messages_download_path(rr) }

      it 'downloads messages as a text file' do
        messages = create_list :text_message, 10, reporting_relationship: rr

        subject

        messages.each do |message|
          expect(response.body).to include(message.number_from) if message.inbound
          expect(response.body).to include(message.number_to) unless message.inbound
          expect(response.body).to include(message.send_at.strftime('%b %-d %Y, %-l:%M:%S %P'))
          expect(response.body).to include(message.body)
          expect(response.body).to include(client.first_name)
          expect(response.body).to include(user.full_name)
        end
      end

      context 'user has recieved image' do
        let(:attachment) { build :attachment, media: File.new('spec/fixtures/fluffy_cat.jpg') }
        before do
          create :text_message, reporting_relationship: rr, attachments: [attachment], inbound: true
        end

        it 'transcript has image indicator' do
          subject
          expect(response.body).to include('Image attachment. See ClientComm conversation for image.')
        end
      end

      context 'some messages may not have been delivered' do
        it 'shows the correct error status' do
          ['maybe_undelivered', 'sending', 'sent', nil].each do |status|
            create :text_message, reporting_relationship: rr, twilio_status: status
          end

          subject

          expect(response.body.scan('MAY BE UNDELIVERED').size).to eq 4
          expect(response.body).to_not include 'NOT DELIVERED'
        end
      end

      context 'some messages were not delivered' do
        it 'shows the correct error status' do
          ['blacklisted', 'failed', 'undelivered'].each do |status|
            create :text_message, reporting_relationship: rr, twilio_status: status
          end

          subject

          expect(response.body.scan('NOT DELIVERED').size).to eq 3
          expect(response.body.scan('UNDELIVERED: ').size).to eq 3
          expect(response.body).to_not include 'MAY BE UNDELIVERED'
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

        subject

        messages.each_with_index do |message, i|
          if i < msgs_count - 1
            expect(response.body.index(message.body)).to be > response.body.index(messages[i + 1].body)
          end
        end
      end

      context 'the user has transfer markers' do
        it 'displays the transfer marker' do
          marker = create :transfer_marker, reporting_relationship: rr

          subject

          expect(response.body).to include("-- #{marker.body} --")
        end
      end

      context 'the user has client edit markers' do
        it 'displays the client edit marker' do
          marker = create :client_edit_marker, reporting_relationship: rr

          subject

          expect(response.body).to include("-- #{marker.body} --")
        end
      end
    end
  end
end
