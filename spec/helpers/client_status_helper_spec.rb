require 'rails_helper'
RSpec.describe ScheduledMessagesHelper, type: :helper do
  context '#client_statuses' do
    let(:user) { create :user }

    before do
      ClientStatus.create!(name: 'Exited', followup_date: 90)

      @client_1 = create :client, user: user, client_status: ClientStatus.find_by_name('Active'), last_contacted_at: active_contacted_at
      @client_2 = create :client, user: user, client_status: ClientStatus.find_by_name('Training'), last_contacted_at: training_contacted_at
      @client_3 = create :client, user: user, client_status: ClientStatus.find_by_name('Exited'), last_contacted_at: exited_contacted_at
      @archived_client = create :client, user: user, client_status: ClientStatus.find_by_name('Exited'), last_contacted_at: exited_contacted_at, active: false
      @client_nil_status = create :client, user: user
      @not_our_client = create :client, client_status: ClientStatus.find_by_name('Exited'), last_contacted_at: exited_contacted_at
    end

    subject { helper.client_statuses(user: user) }

    context 'no clients require followups' do
      let(:training_contacted_at) { Time.now - 24.days }
      let(:active_contacted_at) { Time.now - 24.days }
      let(:exited_contacted_at) { Time.now - 84.days }

      it 'returns empty' do
        expect(subject).to eq({})
      end
    end

    context 'clients require follow up' do
      let(:exited_contacted_at) { Time.now - 86.days }
      let(:active_contacted_at) { nil }
      let(:training_contacted_at) { nil }
      it 'returns the client requiring follow-up' do
        expect(subject).to eq({ 'Exited' => [@client_3.id] })
      end
    end
  end
end
