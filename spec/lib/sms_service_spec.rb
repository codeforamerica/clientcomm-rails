require 'rails_helper'

describe SMSService do
  let(:account) { double('account') }
  let(:client) { instance_double(Twilio::REST::Client, api: double('api', account: account)) }
  let(:message) { double('message') }
  let(:message_sid) { Faker::Crypto.sha1 }
  let(:sid) { 'some_sid' }
  let(:token) { 'some_token' }

  let(:sms_service) { described_class.clone.instance }

  before do
    @sid = ENV['TWILIO_ACCOUNT_SID']
    @token = ENV['TWILIO_AUTH_TOKEN']

    ENV['TWILIO_ACCOUNT_SID'] = sid
    ENV['TWILIO_AUTH_TOKEN'] = token

    allow(Twilio::REST::Client).to receive(:new).with(sid, token).and_return(client)
  end

  after do
    ENV['TWILIO_ACCOUNT_SID'] = @sid
    ENV['TWILIO_AUTH_TOKEN'] = @token
  end

  describe '#send_message' do
    subject { sms_service.send_message(message: factory_message, callback_url: callback_url) }

    let(:callback_url) { 'whocares.com' }
    let(:expected_number) { '+11234567890' }
    let(:factory_message) { create :message, twilio_sid: nil, twilio_status: nil }
    let(:message_status) { ["accepted", "queued", "sending", "sent", "receiving", "received", "delivered"].sample }
    let(:response) { double('response', sid: message_sid, status: message_status) }

    before do
      @twilio_number = ENV['TWILIO_PHONE_NUMBER']
      ENV['TWILIO_PHONE_NUMBER'] = expected_number

      allow(MessageBroadcastJob).to receive(:perform_now)
      allow(account).to receive(:messages).and_return(message)
      allow(message).to receive(:create).and_return(response)
    end

    after do
      ENV['TWILIO_PHONE_NUMBER'] = @twilio_number
    end

    it 'updates the message with twilio info' do
      subject

      expect(message).to have_received(:create).with(
        {
          from:           expected_number,
          to:             factory_message.client.phone_number,
          body:           factory_message.body,
          status_callback: callback_url
        }
      )

      factory_message.reload
      expect(factory_message.twilio_sid).to eq(message_sid)
      expect(factory_message.twilio_status).to eq(message_status)
    end

    it 'creates a MessageBroadcastJob' do
      expect(MessageBroadcastJob).to receive(:perform_now).with(
        message: factory_message
      )

      subject
    end
  end

  describe '#redact_message' do
    let(:message) { instance_double(Message, twilio_sid: message_sid) }

    subject { sms_service.redact_message(message: message) }

    before do
      allow(account).to receive(:messages).with(message_sid).and_return(double('message', fetch: message))
    end

    it 'calls redact on the message' do
      expect(message).to receive(:update).with(body: '')

      expect(subject).to eq true
    end

    context 'message fails to update' do
      let(:error_message) { 'Unable to update record: Cannot delete message because delivery has not been completed.' }

      it 'returns false' do
        expect(message).to receive(:update).with(body: '').and_raise(Twilio::REST::RestError.new(error_message, 20009, 409))

        expect(subject).to eq false
      end
    end

    context 'an unknown twilio error occurs' do
      let(:error) { Twilio::REST::RestError.new('some other error', 20010, 500) }

      it 'reraises the error' do
        expect(message).to receive(:update).with(body: '').and_raise(error)

        expect{ subject }.to raise_error(error)
      end
    end
  end
end
