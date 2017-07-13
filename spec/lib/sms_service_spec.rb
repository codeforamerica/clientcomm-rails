require 'rails_helper'

describe SMSService do
  let(:account) { double('account', messages: messages) }
  let(:messages) { double('messages') }
  let(:user_1) { create :user }
  let(:client_1) { create :client }
  let(:factory_message) { create :message, twilio_sid: nil, twilio_status: nil }

  describe '#send_message' do
    let(:response) { double('response', sid: 'some_sid', status: 'some_status') }
    let(:body) { 'zak and charlie rule' }
    let(:callback_url) { 'whocares.com' }
    subject { described_class.clone.instance }

    before do
      allow(Twilio::REST::Client).to receive(:new).and_return(
        instance_double(Twilio::REST::Client, account: account)
      )
      allow(MessageBroadcastJob).to receive(:perform_now)
    end

    it 'sends twilio a message' do
      expect(messages).to receive(:create).with(
        {
          from: ENV['TWILIO_PHONE_NUMBER'],
          to: factory_message.client.phone_number,
          body: factory_message.body,
          statusCallback: callback_url
        }
      ).and_return(response)

      subject.send_message(message: factory_message, callback_url: callback_url)
    end

    it 'updates the message with twilio info' do
      expect(messages).to receive(:create).with(
        {
          from: ENV['TWILIO_PHONE_NUMBER'],
          to: factory_message.client.phone_number,
          body: factory_message.body,
          statusCallback: callback_url
        }
      ).and_return(response)

      expect(factory_message.twilio_sid).to be_nil
      expect(factory_message.twilio_status).to be_nil


      subject.send_message(message: factory_message, callback_url: callback_url)

      factory_message.reload

      expect(factory_message.twilio_sid).to eq('some_sid')
      expect(factory_message.twilio_status).to eq('some_status')
    end

    it 'creates a MessageBroadcastJob' do
      allow(messages).to receive(:create).and_return(response)

      expect(MessageBroadcastJob).to receive(:perform_now).with(
        message: factory_message,
        is_update: false
      )

      subject.send_message(message: factory_message, callback_url: callback_url)
    end
  end
end
