require 'rails_helper'
RSpec.describe ClientStatusHelper, type: :helper do
  context '#client_statuses' do
    let(:user) { create :user }

    subject { helper.client_statuses(user: user) }

    before do
      create :client_status, name: 'Active', followup_date: 60, department: user.department
      client = create :client, id: 5
      ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: 'Active'),
        last_contacted_at: 56.days.ago
      )
    end

    it 'returns clients requiring follow-up' do
      expect(subject).to eq({ 'Active' => [5] })
    end

    context 'there are inactive clients' do
      before do
        create :client_status, name: 'Active', followup_date: 60, department: user.department
        client = create :client, id: 6
        ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Active'),
          last_contacted_at: 56.days.ago,
          active: false
        )
      end

      it 'returns only the clients requiring follow-up' do
        expect(subject).to eq({ 'Active' => [5] })
      end
    end

    context 'multiple statuses' do
      before do
        create :client_status, name: 'Exited', followup_date: 90, department: user.department
        client = create :client, id: 6
        ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Exited'),
          last_contacted_at: 86.days.ago
        )
      end

      it 'returns the full set of clients requiring follow-up' do
        expect(subject).to eq({ 'Active' => [5], 'Exited' => [6] })
      end

      context 'multiple clients within a status' do
        before do
          create :client_status, name: 'Exited', followup_date: 90, department: user.department
          client = create :client, id: 7
          ReportingRelationship.create(
            user: user,
            client: client,
            client_status: ClientStatus.find_by(name: 'Exited'),
            last_contacted_at: 86.days.ago
          )
        end

        it 'returns the full set of clients requiring follow-up' do
          expect(subject['Active']).to eq([5])
          expect(subject['Exited']).to match_array([6, 7])
        end
      end
    end

    context 'there are clients that do not require follow-up' do
      before do
        create :client_status, name: 'Exited', followup_date: 90, department: user.department
        client = create :client, id: 6
        ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Exited'),
          last_contacted_at: 20.days.ago
        )
      end

      it 'does not return clients not requiring follow-up' do
        expect(subject).to eq({ 'Active' => [5] })
      end
    end
  end
end
