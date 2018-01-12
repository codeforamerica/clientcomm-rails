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
      let(:client) { create :client, user: user }
      let(:message) { create :message, client: client, read: false, user: user }
      let(:user) { correct_user }

      before do
        client.reporting_relationship(user: user)
              .update(has_unread_messages: true)
      end

      subject do
        post message_read_path(message), params: {
          message: {
            read: true
          }
        }
      end

      it 'updates message read' do
        expect(message.reload.read).to eq false

        subject

        expect(message.reload.read).to eq true
      end

      it 'updates client has_unread_messages' do
        expect(client.reporting_relationship(user: correct_user).has_unread_messages).to eq true

        subject

        expect(client.reporting_relationship(user: correct_user).has_unread_messages).to eq false
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
