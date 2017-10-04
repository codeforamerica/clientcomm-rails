require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'relationships' do
    it do
      should belong_to :client
      should belong_to :user
      should have_many :legacy_attachments
    end

    it do
      should validate_presence_of(:send_at).with_message("That date didn't look right.")
    end

    context 'validating body of message' do
      it 'does not validate message with empty body with no attachments' do
        m = Message.create(body: '')
        expect(m.errors[:body].present?).to eq true
      end

      it 'validates empty body with attachment' do
        m = build :message, body: ''
        m.legacy_attachments << build(:legacy_attachment)
        m.save!

        expect(m.save).to be_truthy
        expect(m.legacy_attachments.count).to eq 1
      end
    end

    it 'should validate that a message is scheduled in the future' do
      expect(Message.new.is_past_message).to be_falsey
      expect(Message.new(send_at: Time.current - 1.days).is_past_message).to be_truthy
      expect(Message.new(send_at: Time.current - 6.minutes).is_past_message).to be_truthy
      expect(Message.new(send_at: Time.current).is_past_message).to be_falsey
      expect(Message.new(send_at: Time.current + 5.minutes).is_past_message).to be_falsey
      expect(Message.new(send_at: Time.current + 8.hours).is_past_message).to be_falsey
      expect(Message.new(send_at: Time.current + 8.days).is_past_message).to be_falsey

      message = Message.new(send_at: Time.current - 1.days)
      message.is_past_message
      expect(message.errors[:send_at]).to include "You can't schedule a message in the past."
    end

    it 'should validate that a message is not scheduled more than a year in advance' do
      expect(Message.new(send_at: Time.current + 2.years).valid?).to be_falsey
    end
  end

  describe '#create_from_twilio' do
    context 'client does not exist' do
      let!(:unclaimed_user) { create(:user, email: ENV['UNCLAIMED_EMAIL']) }

      it 'creates a new client with missing information' do
        unknown_number = '+19999999999'
        params = twilio_new_message_params from_number: unknown_number

        message = Message.create_from_twilio!(params)

        expect(message.user).to eq unclaimed_user
        expect(message.number_to).to eq ENV['TWILIO_PHONE_NUMBER']
        expect(message.number_from).to eq unknown_number
        expect(message.inbound).to be_truthy
        expect(message.send_at).to be_present

        client = message.client
        expect(client.first_name).to be_nil
        expect(client.last_name).to eq unknown_number
        expect(client.phone_number).to eq unknown_number
        expect(client.user).to eq unclaimed_user
      end
    end

    context 'client exists' do
      let(:client) { create :client }

      it 'creates a message if proper params are sent' do
        params = twilio_new_message_params from_number: client.phone_number
        msg = Message.create_from_twilio!(params)
        expect(client.messages.last).to eq msg
      end

      it 'creates a message with legacy_attachments' do
        params = twilio_new_message_params(
            from_number: client.phone_number
        ).merge(NumMedia: 2, MediaUrl0: 'whocares.com', MediaUrl1: 'whocares2.com', MediaContentType0: 'text/jpeg', MediaContentType1: 'text/gif')
        msg = Message.create_from_twilio!(params)

        attachments = msg.legacy_attachments.all
        expect(attachments.length).to eq 2

        urls = attachments.map(&:url)
        expect(urls).to match_array(['whocares.com', 'whocares2.com'])

        types = attachments.map(&:content_type)
        expect(types).to match_array(['text/jpeg', 'text/gif'])
      end

      it 'creates a message with no body but an attachment' do
        params = twilio_new_message_params(
            from_number: client.phone_number,
            msg_txt: ''
        ).merge(NumMedia: 1, MediaUrl0: 'whocares.com', MediaContentType0: 'text/jpeg')
        msg = Message.create_from_twilio!(params)

        expect(msg.legacy_attachments.count).to eq 1
        attachment = msg.legacy_attachments.first

        expect(attachment.url).to eq 'whocares.com'
        expect(attachment.content_type).to eq 'text/jpeg'
      end
    end
  end

end
