require 'rails_helper'

describe MessageAlertBuilder do

  describe '#build' do
    let(:client_messages_path) { 'some client messages path' }
    let(:clients_path) { 'all clients path' }
    let(:user) { create :user }
    subject { described_class.build_alert(
        user: user,
        client_messages_path: client_messages_path,
        clients_path: clients_path )
    }

    specify 'when there are no unread messages' do
      expect(subject).to be_nil
    end

    specify 'when there is one unread message' do
      client = create :client, user: user, first_name: "Senay", last_name: "Haylom"
      create :message, user: user, client: client, inbound: true, read: false

      expect(subject).to eq({
        text: 'You have 1 unread message from Senay Haylom',
        link_to: client_messages_path
      })
    end

    specify 'when there is more than one unread message from the same client' do
      client = create :client, user: user, first_name: "Anna", last_name: "Futsum"
      create :message, user: user, client: client, inbound: true, read: false
      create :message, user: user, client: client, inbound: true, read: false

      expect(subject).to eq({
        text: 'You have 2 unread messages from Anna Futsum',
        link_to: client_messages_path
      })
    end

    specify 'when there is more than one unread message from multiple clients' do
      clientone = create :client, user: user, first_name: "Aziz", last_name: "Yonas"
      clienttwo = create :client, user: user, first_name: "Mustafa", last_name: "Semhar"
      create :message, user: user, client: clientone, inbound: true, read: false
      create :message, user: user, client: clienttwo, inbound: true, read: false
      expect(subject).to eq({
        text: 'You have 2 unread messages',
        link_to: clients_path
      })
    end

    specify 'when there are a mixture of read and unread messages from a client' do
      client = create :client, user: user, first_name: "Luwam", last_name: "Sayid"
      create :message, user: user, client: client, inbound: true, read: true
      create :message, user: user, client: client, inbound: true, read: true
      create :message, user: user, client: client, inbound: true, read: false
      expect(subject).to eq({
        text: "You have 1 unread message from Luwam Sayid",
        link_to: client_messages_path
      })
    end

    specify "when there are unread messages for a different user's clients" do
      other_user = create :user
      client = create :client, user: other_user, first_name: 'Demet', last_name: 'Zula'
      create :message, user: other_user, client: client, inbound: true, read: false
      create :message, user: other_user, client: client, inbound: true, read: false
      expect(subject).to eq nil
    end

  end
end
