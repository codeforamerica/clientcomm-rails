require 'rails_helper'

describe 'reads', type: :request do
  describe 'reads#create' do
    let(:rr) { create :reporting_relationship, has_unread_messages: true }
    let(:user) { rr.user }
    let(:client) { rr.client }
    let(:message) { create :text_message, reporting_relationship: rr, read: false }

    before do
      sign_in user
    end

    subject do
      post message_read_path(message), params: {
        message: {
          read: true
        }
      }
    end

    it 'updates message read' do
      subject
      expect(message.reload.read).to eq true
    end

    it 'updates client has_unread_messages' do
      subject
      expect(rr.reload.has_unread_messages).to eq false
      expect(user.has_unread_messages).to eq false
    end

    context 'message does not belong to user' do
      let(:user) { create :user }

      it 'throws an error if message does not belong to user' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
