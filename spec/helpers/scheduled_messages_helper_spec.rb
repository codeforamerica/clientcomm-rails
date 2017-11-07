require 'rails_helper'
RSpec.describe ScheduledMessagesHelper, type: :helper do
  context 'Scheduled Messages' do
    let(:user) { create :user }
    let(:client) { create :client, user: user }
    let!(:scheduled_messages) { create_list(:message, 5, user: user, client: client, send_at: Time.now.tomorrow) }
    let!(:sent_messages) { create_list(:message, 5, user: user, client: client) }
    let!(:unrelated_messages) { create_list(:message, 5, user: user) }

    context '#scheduled_messages' do
      it 'returns all unsent scheduled messages' do
        expect(helper.scheduled_messages(client: client)).to match_array(scheduled_messages)
      end
    end
  end
end
