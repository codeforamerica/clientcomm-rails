require 'rails_helper'

describe 'reads', type: :request do
  let(:correct_user) { create :user }
  let(:invalid_user) { create :user }

  context 'authenticated' do
    before do
      sign_in correct_user
    end

    describe 'reads#create' do
      let(:user) { create :user }
      let(:client) { create :client, user: user, has_unread_messages: true }
      let(:message) { create :message, client: client, read: false, user: user }
      let(:user) { correct_user }

      subject do
        post message_read_path(message, {
                                 message: {
                                   read: true
                                 }
                               })
      end

      it 'updates message read' do
        subject

        expect(Message.find(message.id).read).to eq true
      end

      it 'updates client has_unread_messages' do
        subject

        expect(Client.find(client.id).has_unread_messages).to eq false
      end

      context 'message does not belong to user' do
        let(:user) { invalid_user }

        it 'throws an error if message does not belong to user' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
