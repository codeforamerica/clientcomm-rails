require 'rails_helper'
require 'cgi'

describe SMSService do
  let(:twilio_client) { FakeTwilioClient.new sid, token }
  let(:message_sid) { Faker::Crypto.sha1 }
  let(:sid) { 'some_sid' }
  let(:token) { 'some_token' }

  let(:sms_service) { described_class.clone.instance }

  before do
    @sid = ENV['TWILIO_ACCOUNT_SID']
    @token = ENV['TWILIO_AUTH_TOKEN']

    ENV['TWILIO_ACCOUNT_SID'] = sid
    ENV['TWILIO_AUTH_TOKEN'] = token

    allow(Twilio::REST::Client).to receive(:new).with(sid, token).and_return(twilio_client)
  end

  after do
    ENV['TWILIO_ACCOUNT_SID'] = @sid
    ENV['TWILIO_AUTH_TOKEN'] = @token
  end

  describe '#send_message' do
    subject { sms_service.send_message(message: factory_message, callback_url: callback_url) }

    let(:callback_url) { 'whocares.com' }
    let(:expected_number) { '+11234567890' }
    let(:factory_message) { create :message, twilio_sid: nil, twilio_status: nil, number_from: expected_number }
    let(:message_status) { ['accepted', 'queued', 'sending', 'sent', 'receiving', 'received', 'delivered'].sample }
    let(:response) { double('response', sid: message_sid, status: message_status) }

    before do
      allow(MessageBroadcastJob).to receive(:perform_now)
      allow(twilio_client).to receive(:create).and_return(response)
    end

    it 'updates the message with twilio info' do
      subject

      expect(twilio_client).to have_received(:create).with(
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
    let(:message) { double('twilio_message', twilio_sid: message_sid) }
    let(:media_one) { double('media') }
    let(:media_two) { double('media') }
    let(:media_list) { [media_one, media_two] }

    subject { sms_service.redact_message(message: message) }

    before do
      allow(twilio_client).to receive(:messages).with(message_sid).and_return(twilio_client)
      allow(twilio_client).to receive(:fetch).and_return(message)
      allow(message).to receive(:update)
      allow(message).to receive(:num_media).and_return('0')
      allow(media_one).to receive(:delete)
      allow(media_two).to receive(:delete)
    end

    it 'calls redact on the message' do
      expect(message).to receive(:update).with(body: '')

      expect(subject).to eq true
    end

    context 'messages has attached media' do
      before do
        allow(message).to receive(:num_media).and_return('2')
      end

      it 'deletes any associated media' do
        expect(message).to receive(:media).and_return(double('list', list: media_list))

        media_list.each do |media|
          expect(media).to receive(:delete)
        end

        expect(subject).to eq true
      end
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

        expect { subject }.to raise_error(error)
      end
    end
  end

  describe '#number_lookup' do
    let(:phone_numbers) { double('phone_numbers') }
    let(:phone_number) { '12345678910' }

    subject { sms_service.number_lookup(phone_number: phone_number) }

    it 'looks up the phone number' do
      expect(twilio_client).to receive(:phone_numbers).with(ERB::Util.url_encode(phone_number)).and_return(phone_numbers)
      expect(phone_numbers).to receive(:fetch)
        .with(no_args)
        .and_return(double('phone_number', phone_number: 'some phone number'))

      expect(subject).to eq('some phone number')
    end

    context 'the number does not exist' do
      let(:error) { Twilio::REST::RestError.new('Unable to fetch record', 20404, 404) }
      it 'throws a number not found error' do
        expect(twilio_client).to receive(:phone_numbers).with(ERB::Util.url_encode(phone_number)).and_return(phone_numbers)
        expect(phone_numbers).to receive(:fetch).and_raise(error)

        expect { subject }.to raise_error(SMSService::NumberNotFound)
      end

      context 'an unknown twilio error occurs' do
        let(:error) { Twilio::REST::RestError.new('some other error', 20010, 500) }

        it 'reraises the error' do
          expect(twilio_client).to receive(:phone_numbers).with(ERB::Util.url_encode(phone_number)).and_return(phone_numbers)
          expect(phone_numbers).to receive(:fetch).and_raise(error)

          expect { subject }.to raise_error(error)
        end
      end
    end
  end
end
