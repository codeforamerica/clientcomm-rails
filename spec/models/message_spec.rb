require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'relationships' do
    it do
      should belong_to :client
      should belong_to :user
      should have_many :attachments
    end
  end

  describe '#create_from_twilio' do
    let(:user) { create :user }
    let(:client) { create :client, user: user }

    context 'client does not exist' do
      it 'errors' do
        params = twilio_new_message_params from_number: '+99999999999'
        expect {
          Message.create_from_twilio!(params)
        }.to raise_exception ActiveRecord::RecordNotFound
      end
    end

    context 'client exists' do
      it 'creates a message if proper params are sent' do
        params = twilio_new_message_params from_number: client.phone_number
        msg = Message.create_from_twilio!(params)
        expect(client.messages.last).to eq msg
      end

      it 'creates a message with attachments' do
        params = twilio_new_message_params(
            from_number: client.phone_number, media_count: 2
        )
        msg = Message.create_from_twilio!(params)
        expect(msg).not_to eq nil

        attachments = msg.attachments.all
        expect(attachments.length).to eq 2

        urls = attachments.map(&:url)
        expect(urls).to match_array(params.fetch_values('MediaUrl0', 'MediaUrl1'))

        types = attachments.map(&:content_type)
        expect(types).to match_array(params.fetch_values('MediaContentType0', 'MediaContentType1'))
      end
    end
  end

end
