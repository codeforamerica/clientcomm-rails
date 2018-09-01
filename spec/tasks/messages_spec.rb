require 'rails_helper'
require 'rake'

describe 'messages rake tasks' do
  describe 'messages:update_twilio_statuses', active_job: true do
    let(:twilio_client) { FakeTwilioClient.new sid, token }
    let(:sid) { 'some_sid' }
    let(:token) { 'some_token' }

    let(:twilio_message) { double('twilio_message', status: 'delivered') }

    let!(:broken_message) { create :text_message, inbound: false, twilio_status: 'accepted' }
    let!(:accepted_message) { create :text_message, inbound: false, twilio_status: 'accepted' }
    let!(:queued_message) { create :text_message, inbound: false, twilio_status: 'queued' }
    let!(:sending_message) { create :text_message, inbound: false, twilio_status: 'sending' }
    let!(:delivered_message) { create :text_message, inbound: false, twilio_status: 'delivered' }
    let!(:undelivered_message) { create :text_message, inbound: false, twilio_status: 'undelivered' }
    let!(:failed_message) { create :text_message, inbound: false, twilio_status: 'failed' }
    let!(:blacklisted_message) { create :text_message, inbound: false, twilio_status: 'blacklisted' }
    let!(:received_message) { create :text_message, inbound: true, twilio_status: 'received' }
    let!(:old_message) { create :text_message, inbound: false, twilio_status: 'sent', send_at: Time.current - 10.days }

    before do
      load File.expand_path('../../lib/tasks/messages.rake', __dir__)
      Rake::Task.define_task(:environment)

      @sid = ENV['TWILIO_ACCOUNT_SID']
      @token = ENV['TWILIO_AUTH_TOKEN']
      ENV['TWILIO_ACCOUNT_SID'] = sid
      ENV['TWILIO_AUTH_TOKEN'] = token

      allow(Rails.logger).to receive :warn
    end

    after do
      ENV['TWILIO_ACCOUNT_SID'] = @sid
      ENV['TWILIO_AUTH_TOKEN'] = @token
    end

    it 'updates the status of transient messages' do
      now = Time.zone.now.change(usec: 0)
      transient_messages = Message.where.not(inbound: true, twilio_status: %w[failed delivered undelivered blacklisted maybe_undelivered])
      undelivered_messages = Message.where(twilio_status: 'undelivered')
      received_messages = Message.where(twilio_status: 'received')

      expect(Rails.logger).to receive(:warn).with("updating #{transient_messages.count} transient messages")
      expect(Rails.logger).to receive(:warn).with("updating transient message #{accepted_message.id}")
      expect(Rails.logger).to receive(:warn).with("updating transient message #{queued_message.id}")
      expect(Rails.logger).to receive(:warn).with("updating transient message #{sending_message.id}")

      expect(SMSService.instance).to receive(:status_lookup)
        .with(message: accepted_message)
        .and_return('sent')
      expect(SMSService.instance).to receive(:status_lookup)
        .with(message: queued_message)
        .and_return('accepted')
      expect(SMSService.instance).to receive(:status_lookup)
        .with(message: sending_message)
        .and_return('delivered')
      expect(SMSService.instance).to_not receive(:status_lookup)
        .with(message: failed_message)
      expect(SMSService.instance).to_not receive(:status_lookup)
        .with(message: delivered_message)
      expect(SMSService.instance).to_not receive(:status_lookup)
        .with(message: undelivered_message)
      expect(SMSService.instance).to_not receive(:status_lookup)
        .with(message: blacklisted_message)
      expect(SMSService.instance).to_not receive(:status_lookup)
        .with(message: old_message)

      expect(SMSService.instance).to receive(:redact_message)
        .with(message: accepted_message.reload)
        .and_return(false)
      expect(SMSService.instance).to receive(:redact_message)
        .with(message: queued_message.reload)
        .and_return(false)
      expect(SMSService.instance).to receive(:redact_message)
        .with(message: sending_message.reload)
        .and_return(true)
      expect(SMSService.instance).to receive(:status_lookup)
        .with(message: broken_message.reload)
        .and_raise(Twilio::REST::RestError.new('Unable to fetch record', 20404, 404))

      expect(transient_messages.count).to eq 5
      expect(undelivered_messages.count).to eq 1
      expect(received_messages.count).to eq 1
      expect(CLOUD_WATCH).to receive(:put_metric_data).with(
        namespace: ENV['DEPLOYMENT'],
        metric_data: [
          {
            metric_name: 'TwilioStatus404',
            timestamp: now,
            value: 1,
            unit: 'None',
            storage_resolution: 1
          }
        ]
      )
      expect(Rails.logger).to receive(:warn).with("404 getting message status from Twilio sid: #{broken_message.twilio_sid}")

      travel_to now do
        perform_enqueued_jobs do
          Rake::Task['messages:update_twilio_statuses'].invoke
        end
      end
      expect(old_message.reload.twilio_status).to eq('maybe_undelivered')
      expect(transient_messages.count).to eq 3
      expect(undelivered_messages.count).to eq 1
      expect(received_messages.count).to eq 1
    end
  end
end
