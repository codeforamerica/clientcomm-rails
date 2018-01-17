require 'rails_helper'
require 'rake'

describe 'messages rake tasks' do
  describe 'messages:update_twilio_statuses' do
    let(:twilio_client) { FakeTwilioClient.new sid, token }
    let(:sid) { 'some_sid' }
    let(:token) { 'some_token' }

    let(:twilio_message) { double('twilio_message', status: 'delivered') }

    before do
      load File.expand_path('../../../lib/tasks/messages.rake', __FILE__)
      Rake::Task.define_task(:environment)

      @sid = ENV['TWILIO_ACCOUNT_SID']
      @token = ENV['TWILIO_AUTH_TOKEN']
      ENV['TWILIO_ACCOUNT_SID'] = sid
      ENV['TWILIO_AUTH_TOKEN'] = token

      allow(SMSService.instance).to receive(:status_lookup)
        .and_return('delivered')

      create_list :message, 3, inbound: false, twilio_status: 'accepted'
      create_list :message, 3, inbound: false, twilio_status: 'queued'
      create_list :message, 3, inbound: false, twilio_status: 'sending'
      create_list :message, 3, inbound: false, twilio_status: 'delivered'
      create_list :message, 3, inbound: false, twilio_status: 'undelivered'
      create_list :message, 3, inbound: true, twilio_status: 'received'
    end

    after do
      ENV['TWILIO_ACCOUNT_SID'] = @sid
      ENV['TWILIO_AUTH_TOKEN'] = @token
    end

    it 'updates the status of transient messages' do
      transient_messages = Message.where.not(inbound: true, twilio_status: %w[delivered undelivered])
      undelivered_messages = Message.where(twilio_status: 'undelivered')
      received_messages = Message.where(twilio_status: 'received')

      expect(transient_messages.count).to eq 9
      expect(undelivered_messages.count).to eq 3
      expect(received_messages.count).to eq 3

      Rake::Task['messages:update_twilio_statuses'].invoke

      expect(transient_messages.count).to eq 0
      expect(undelivered_messages.count).to eq 3
      expect(received_messages.count).to eq 3
    end
  end
end
