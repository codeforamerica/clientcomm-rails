require 'rails_helper'

describe SMSService do
  let(:account) { double('account', messages: messages) }
  let(:messages) { double('messages') }
  let(:user_1) { create :user }
  let(:client_1) { create :client }
  let(:factory_message) { create :message, twilio_sid: nil, twilio_status: nil }
  let(:callback_url) { 'whocares.com' }
  subject { described_class.clone.instance }

  describe '#send_message' do
    let(:response) { double('response', sid: 'some_sid', status: 'some_status') }
    let(:body) { 'zak and charlie rule' }
    let(:expected_number) { PhoneNumberParser.normalize(ENV['TWILIO_PHONE_NUMBER']) }

    before do
      allow(Twilio::REST::Client).to receive(:new).and_return(
        instance_double(Twilio::REST::Client, account: account)
      )
      allow(MessageBroadcastJob).to receive(:perform_now)
    end

    it 'sends twilio a message' do
      expect(messages).to receive(:create).with(
        {
          from:           expected_number,
          to:             factory_message.client.phone_number,
          body:           factory_message.body,
          statusCallback: callback_url
        }
      ).and_return(response)

      subject.send_message(message: factory_message, callback_url: callback_url)
    end

    it 'updates the message with twilio info' do
      expect(messages).to receive(:create).with(
        {
          from:           expected_number,
          to:             factory_message.client.phone_number,
          body:           factory_message.body,
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
        message: factory_message
      )

      subject.send_message(message: factory_message, callback_url: callback_url)
    end
  end

  describe '#send_mass_message' do
    let(:user) { instance_double(User) }

    let(:client_1) { instance_double(Client, phone_number: client_1_number) }
    let(:client_1_number) { double("Some number 1") }
    let(:client_2) { instance_double(Client, phone_number: client_2_number) }
    let(:client_2_number) { double("Some number 2") }

    let(:client_ids) { ["1", "2"] }
    let(:message_body) { "this is an example message" }

    let(:message_1) { instance_double(Message, send_at: '1') }
    let(:message_2) { instance_double(Message, send_at: '2') }

    before do
      allow(Client).to receive(:find)
                         .with("1")
                         .and_return(client_1)

      allow(Client).to receive(:find)
                         .with("2")
                         .and_return(client_2)

      allow(Time).to receive(:now).and_return("now")
    end

    it 'creates a message for each client id' do
      expect(Message).to receive(:create!).with({
                                                  body:        message_body,
                                                  user:        user,
                                                  client:      client_1,
                                                  number_from: ENV['TWILIO_PHONE_NUMBER'],
                                                  number_to:   client_1_number,
                                                  read:        true,
                                                  inbound:     false,
                                                  send_at:     "now"
                                                }).and_return(message_1)

      expect(Message).to receive(:create!).with({
                                                  body:        message_body,
                                                  user:        user,
                                                  client:      client_2,
                                                  number_from: ENV['TWILIO_PHONE_NUMBER'],
                                                  number_to:   client_2_number,
                                                  read:        true,
                                                  inbound:     false,
                                                  send_at:     "now"
                                                }).and_return(message_2)

      expect(ScheduledMessageJob).to receive(:perform_later).with({
                                                                    message:      message_1,
                                                                    send_at:      1,
                                                                    callback_url: callback_url
                                                                  })

      expect(ScheduledMessageJob).to receive(:perform_later).with({
                                                                    message:      message_2,
                                                                    send_at:      2,
                                                                    callback_url: callback_url
                                                                  })

      mass_message = MassMessage.new(user: user, clients: client_ids, message: message_body)
      subject.send_mass_message(mass_message: mass_message, callback_url: callback_url)
    end

    context 'when there is an empty string in client_ids' do
      let(:client_ids) { ["", "1", "2"] }

      it 'ignores the empty string and creates a message for each client id' do
        expect(Message).to receive(:create!).with({
                                                    body:        message_body,
                                                    user:        user,
                                                    client:      client_1,
                                                    number_from: ENV['TWILIO_PHONE_NUMBER'],
                                                    number_to:   client_1_number,
                                                    read:        true,
                                                    inbound:     false,
                                                    send_at:     "now"
                                                  }).and_return(message_1)

        expect(Message).to receive(:create!).with({
                                                    body:        message_body,
                                                    user:        user,
                                                    client:      client_2,
                                                    number_from: ENV['TWILIO_PHONE_NUMBER'],
                                                    number_to:   client_2_number,
                                                    read:        true,
                                                    inbound:     false,
                                                    send_at:     "now"
                                                  }).and_return(message_2)

        expect(ScheduledMessageJob).to receive(:perform_later).with({
                                                                      message:      message_1,
                                                                      send_at:      1,
                                                                      callback_url: callback_url
                                                                    })

        expect(ScheduledMessageJob).to receive(:perform_later).with({
                                                                      message:      message_2,
                                                                      send_at:      2,
                                                                      callback_url: callback_url
                                                                    })

        mass_message = MassMessage.new(user: user, clients: client_ids, message: message_body)
        subject.send_mass_message(mass_message: mass_message, callback_url: callback_url)
      end
    end
  end
end
