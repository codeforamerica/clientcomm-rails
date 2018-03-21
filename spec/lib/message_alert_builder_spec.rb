require 'rails_helper'

describe MessageAlertBuilder do
  describe '#build' do
    let(:reporting_relationship_path) { 'some client messages path' }
    let(:clients_path) { 'all clients path' }
    let(:client) { create :client, first_name: 'Zak', last_name: 'Soup' }
    let(:rr) { create :reporting_relationship, client: client }

    subject do
      described_class.build_alert(
        reporting_relationship: rr,
        reporting_relationship_path: reporting_relationship_path,
        clients_path: clients_path
      )
    end

    context 'there are no unread messages' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'there is one unread message' do
      before do
        create :message, reporting_relationship: rr, inbound: true, read: false
      end

      it 'reports there is one unread message' do
        expect(subject).to eq(
          {
            text: 'You have 1 unread message from Zak Soup',
            link_to: reporting_relationship_path
          }
        )
      end
    end

    context 'there is more than one unread message from the same client' do
      before do
        create :message, reporting_relationship: rr, inbound: true, read: false
        create :message, reporting_relationship: rr, inbound: true, read: false
      end

      it 'returns the correct count of unread messages' do
        expect(subject).to eq(
          {
            text: 'You have 2 unread messages from Zak Soup',
            link_to: reporting_relationship_path
          }
        )
      end
    end

    context 'there is more than one unread message from multiple clients' do
      let(:client2) { create :client, first_name: 'Glass', last_name: 'Resistor' }
      let(:rr2) { create :reporting_relationship, client: client2, user: rr.user }

      before do
        create :message, reporting_relationship: rr, inbound: true, read: false
        create :message, reporting_relationship: rr2, inbound: true, read: false
      end

      it 'returns the correct count of unread messages without full_name' do
        expect(subject).to eq(
          {
            text: 'You have 2 unread messages',
            link_to: clients_path
          }
        )
      end
    end

    context 'there are a mixture of read and unread messages from a client' do
      before do
        create :message, reporting_relationship: rr, inbound: true, read: true
        create :message, reporting_relationship: rr, inbound: true, read: true
        create :message, reporting_relationship: rr, inbound: true, read: false
      end

      it 'only reports unread messages' do
        expect(subject).to eq(
          {
            text: 'You have 1 unread message from Zak Soup',
            link_to: reporting_relationship_path
          }
        )
      end
    end

    context 'there are multiple clients' do
      let(:clientone) { create :client, user: user, first_name: 'Zarka', last_name: 'Viktor' }
      let(:clienttwo) { create :client, user: user, first_name: 'Thury', last_name: 'Izsak' }
      let(:clientthree) { create :client, user: user, first_name: 'Asztalos', last_name: 'Bernadett' }
      let(:rrone) { ReportingRelationship.find_by(user: user, client: clientone) }
      let(:rrtwo) { ReportingRelationship.find_by(user: user, client: clienttwo) }
      let(:rrthree) { ReportingRelationship.find_by(user: user, client: clientthree) }

      before do
        create :message, reporting_relationship: rrone, inbound: true, read: false
        create :message, reporting_relationship: rrtwo, inbound: true, read: false
        create :message, reporting_relationship: rrthree, inbound: true, read: false
        ReportingRelationship.find_by(user: user, client: clientone).update!(has_unread_messages: true)
        ReportingRelationship.find_by(user: user, client: clienttwo).update!(has_unread_messages: true)
        ReportingRelationship.find_by(user: user, client: clientthree).update!(has_unread_messages: true)
      end

      context 'only one is inactive' do
        specify 'when there are unread messages on a deactivated client' do
          ReportingRelationship.find_by(user: user, client: clienttwo).update!(active: false)
          expect(subject).to eq({
                                  text: 'You have 2 unread messages',
                                  link_to: clients_path
                                })
        end
      end

      context 'only one is active' do
        specify 'when there are unread messages on a deactivated client' do
          ReportingRelationship.find_by(user: user, client: clientone).update!(active: false)
          ReportingRelationship.find_by(user: user, client: clienttwo).update!(active: false)
          expect(subject).to eq({
                                  text: 'You have 1 unread message from Asztalos Bernadett',
                                  link_to: reporting_relationship_path
                                })
        end
      end
    end
  end
end
