require 'rails_helper'
require 'rake'

describe 'messages rake tasks' do
  describe 'messages:update_twilio_statuses', active_job: true do
    let(:twilio_client) { FakeTwilioClient.new sid, token }
    let(:sid) { 'some_sid' }
    let(:token) { 'some_token' }

    let(:twilio_message) { double('twilio_message', status: 'delivered') }

    let!(:accepted_message) { create :text_message, inbound: false, twilio_status: 'accepted' }
    let!(:queued_message) { create :text_message, inbound: false, twilio_status: 'queued' }
    let!(:sending_message) { create :text_message, inbound: false, twilio_status: 'sending' }
    let!(:delivered_message) { create :text_message, inbound: false, twilio_status: 'delivered' }
    let!(:undelivered_message) { create :text_message, inbound: false, twilio_status: 'undelivered' }
    let!(:received_message) { create :text_message, inbound: true, twilio_status: 'received' }

    before do
      load File.expand_path('../../lib/tasks/messages.rake', __dir__)
      Rake::Task.define_task(:environment)

      @sid = ENV['TWILIO_ACCOUNT_SID']
      @token = ENV['TWILIO_AUTH_TOKEN']
      ENV['TWILIO_ACCOUNT_SID'] = sid
      ENV['TWILIO_AUTH_TOKEN'] = token

      allow(Rails.logger).to receive :info
    end

    after do
      ENV['TWILIO_ACCOUNT_SID'] = @sid
      ENV['TWILIO_AUTH_TOKEN'] = @token
    end

    it 'updates the status of transient messages' do
      transient_messages = Message.where.not(inbound: true, twilio_status: %w[delivered undelivered])
      undelivered_messages = Message.where(twilio_status: 'undelivered')
      received_messages = Message.where(twilio_status: 'received')

      expect(Rails.logger).to receive(:info).with("updating #{transient_messages.count} transient messages")
      expect(Rails.logger).to receive(:info).with("updating transient message #{accepted_message.id}")
      expect(Rails.logger).to receive(:info).with("updating transient message #{queued_message.id}")
      expect(Rails.logger).to receive(:info).with("updating transient message #{sending_message.id}")

      expect(SMSService.instance).to receive(:status_lookup)
        .with(message: accepted_message)
        .and_return('sent')
      expect(SMSService.instance).to receive(:status_lookup)
        .with(message: queued_message)
        .and_return('accepted')
      expect(SMSService.instance).to receive(:status_lookup)
        .with(message: sending_message)
        .and_return('delivered')

      expect(SMSService.instance).to receive(:redact_message)
        .with(message: accepted_message.reload)
        .and_return(false)
      expect(SMSService.instance).to receive(:redact_message)
        .with(message: queued_message.reload)
        .and_return(false)
      expect(SMSService.instance).to receive(:redact_message)
        .with(message: sending_message.reload)
        .and_return(true)

      expect(transient_messages.count).to eq 3
      expect(undelivered_messages.count).to eq 1
      expect(received_messages.count).to eq 1

      perform_enqueued_jobs do
        Rake::Task['messages:update_twilio_statuses'].invoke
      end

      expect(transient_messages.count).to eq 2
      expect(undelivered_messages.count).to eq 1
      expect(received_messages.count).to eq 1
    end
  end
end
