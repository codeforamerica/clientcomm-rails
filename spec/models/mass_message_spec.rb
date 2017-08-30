require 'rails_helper'

RSpec.describe MassMessage, type: :model do
  describe 'send_to_all' do
    let(:user) { instance_double(User) }

    let(:client_1) { instance_double(Client, phone_number: client_1_number) }
    let(:client_1_number) { double("Some number 1") }
    let(:client_2) { instance_double(Client, phone_number: client_2_number) }
    let(:client_2_number) { double("Some number 2") }

    let(:client_ids) { ["1", "2"] }
    let(:message) { "this is an example message" }

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
        body: message,
        user: user,
        client: client_1,
        number_from: ENV['TWILIO_PHONE_NUMBER'],
        number_to: client_1_number,
        read: true,
        inbound: false,
        send_at: "now"
      })

      expect(Message).to receive(:create!).with({
        body: message,
        user: user,
        client: client_2,
        number_from: ENV['TWILIO_PHONE_NUMBER'],
        number_to: client_2_number,
        read: true,
        inbound: false,
        send_at: "now"
      })

      mass_message = MassMessage.new(user: user, clients: client_ids, message: message)
      mass_message.send_to_all
    end

    context 'when there is an empty string in client_ids' do
      let(:client_ids) { ["", "1", "2"] }

      it 'ignores the empty string and creates a message for each client id' do
        expect(Message).to receive(:create!).with({
          body: message,
          user: user,
          client: client_1,
          number_from: ENV['TWILIO_PHONE_NUMBER'],
          number_to: client_1_number,
          read: true,
          inbound: false,
          send_at: "now"
        })

        expect(Message).to receive(:create!).with({
          body: message,
          user: user,
          client: client_2,
          number_from: ENV['TWILIO_PHONE_NUMBER'],
          number_to: client_2_number,
          read: true,
          inbound: false,
          send_at: "now"
        })

        mass_message = MassMessage.new(user: user, clients: client_ids, message: message)
        mass_message.send_to_all
      end
    end
  end
end
