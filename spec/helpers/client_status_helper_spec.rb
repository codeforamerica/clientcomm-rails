require 'rails_helper'
RSpec.describe ClientStatusHelper, type: :helper do
  context '#relationships_with_statuses_due_for_follow_up' do
    let(:user) { create :user }

    subject { helper.relationships_with_statuses_due_for_follow_up(user: user) }

    before do
      create :client_status, name: 'Active', followup_date: 60, department: user.department
      client = create :client
      @rr1 = ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: 'Active'),
        last_contacted_at: 56.days.ago
      )
    end

    it 'returns clients requiring follow-up' do
      expect(subject).to eq({ 'Active' => [@rr1.id] })
    end

    context 'there are inactive clients' do
      before do
        create :client_status, name: 'Active', followup_date: 60, department: user.department
        client = create :client
        @rr2 = ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Active'),
          last_contacted_at: 56.days.ago,
          active: false
        )
      end

      it 'returns only the clients requiring follow-up' do
        expect(subject).to eq({ 'Active' => [@rr1.id] })
      end
    end

    context 'multiple statuses' do
      before do
        create :client_status, name: 'Exited', followup_date: 90, department: user.department
        client = create :client
        @rr2 = ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Exited'),
          last_contacted_at: 86.days.ago
        )
      end

      it 'returns the full set of clients requiring follow-up' do
        expect(subject).to eq({ 'Active' => [@rr1.id], 'Exited' => [@rr2.id] })
      end

      context 'multiple clients within a status' do
        before do
          create :client_status, name: 'Exited', followup_date: 90, department: user.department
          client = create :client
          @rr3 = ReportingRelationship.create(
            user: user,
            client: client,
            client_status: ClientStatus.find_by(name: 'Exited'),
            last_contacted_at: 86.days.ago
          )
        end

        it 'returns the full set of clients requiring follow-up' do
          expect(subject['Active']).to eq([@rr1.id])
          expect(subject['Exited']).to match_array([@rr2.id, @rr3.id])
        end
      end
    end

    context 'there are clients that do not require follow-up' do
      before do
        create :client_status, name: 'Exited', followup_date: 90, department: user.department
        client = create :client
        @rr2 = ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Exited'),
          last_contacted_at: 20.days.ago
        )
      end

      it 'does not return clients not requiring follow-up' do
        expect(subject).to eq({ 'Active' => [@rr1.id] })
      end
    end

    context 'there are clients with null follow-up dates' do
      before do
        @status = create :client_status, name: 'Exited', department: user.department
        client = create :client
        @rr2 = ReportingRelationship.create(
          user: user,
          client: client,
          client_status: @status,
          last_contacted_at: 0
        )
      end

      it 'does not return clients with statuses with nil followup_date' do
        subject
        expect(subject).to eq({ 'Active' => [@rr1.id] })
      end
    end
  end
end
