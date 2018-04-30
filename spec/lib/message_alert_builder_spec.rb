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
          text: 'You have 1 unread message from Zak Soup',
          link_to: reporting_relationship_path
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
          text: 'You have 2 unread messages from Zak Soup',
          link_to: reporting_relationship_path
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
          text: 'You have 2 unread messages',
          link_to: clients_path
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
          text: 'You have 1 unread message from Zak Soup',
          link_to: reporting_relationship_path
        )
      end
    end
  end
end
