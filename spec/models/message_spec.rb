require 'rails_helper'

RSpec.describe Message, type: :model do
  let!(:user) { create :user }
  let!(:client) { create :client, :user => user }
  let!(:message) { create :message, :user => user, :client => client}

  describe 'relationship to client' do
    it 'belongs to a client' do
      expect(message.client).to eq(client)
    end
  end

  describe 'relationship to user' do
    it 'belings to a user' do
      expect(message.user).to eq(user)
    end
  end

  describe '#create_from_twilio' do
    it 'errors if no client matches the passed phone number' do
      params = twilio_new_message_params from_number: '+99999999999'
      expect {
        Message.create_from_twilio!(params)
      }.to raise_exception ActiveRecord::RecordNotFound
    end

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
      atts = msg.attachments.all
      expect(atts.length).to eq 2
      urls = atts.map(&:url)
      types = atts.map(&:content_type)
      expect(urls).to match_array(params.fetch_values('MediaUrl0', 'MediaUrl1'))
      expect(types).to match_array(params.fetch_values('MediaContentType0', 'MediaContentType1'))
    end
  end

end
