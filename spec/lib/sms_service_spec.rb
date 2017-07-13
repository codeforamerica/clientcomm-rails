require 'rails_helper'

describe SMSService do
  let(:account) { double('account', messages: messages) }
  let(:messages) { double('messages') }
  let(:user_1) { build :user }
  let(:client_1) { build :client }

  describe '#send_message' do
    let(:response) { double('response', sid: 'some_sid', status: 'some_status') }
    let(:body) { 'zak and charlie rule' }
    let(:callback_url) { 'whocares.com' }
    let(:fake_message) { instance_double(Message) }
    subject { described_class.clone.instance }

    before do
      allow(Twilio::REST::Client).to receive(:new).and_return(
        instance_double(Twilio::REST::Client, account: account)
      )
    end

    it 'sends twilio a message' do
      expect(messages).to receive(:create).with(
        {
          from: ENV['TWILIO_PHONE_NUMBER'],
          to: client_1.phone_number,
          body: body,
          statusCallback: callback_url
        }
      ).and_return(response)

      subject.send_message(user: user_1,
        client: client_1,
        body: body,
        callback_url: callback_url)
    end

    it 'saves a message model' do
      allow(messages).to receive(:create).and_return(response)

      subject.send_message(user: user_1,
        client: client_1,
        body: body,
        callback_url: callback_url)

      expect(Message.last.body).to eq(body)
      expect(Message.last.number_to).to eq(client_1.phone_number)
    end

    it 'creates a MessageBroadcastJob' do
      allow(messages).to receive(:create).and_return(response)

      allow(Message).to receive(:create).and_return(fake_message)

      expect(MessageBroadcastJob).to receive(:perform_now).with(
        message: fake_message,
        is_update: false
      )

      subject.send_message(user: user_1,
        client: client_1,
        body: body,
        callback_url: callback_url)
    end
  end
end
