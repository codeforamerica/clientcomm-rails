require 'rails_helper'

describe MessageAlertBuilder do

  describe '#build' do
    specify 'when there are no unread messages' do
      user = create :user
      expect(described_class.new.build(user: user)).to eq nil
    end

    specify "when there are unread messages for a different user's clients" do
      userone = create :user
      usertwo = create :user
      client = create :client, user: userone, first_name: "Donald", last_name: "Duck"
      create :message, user: userone, client: client, inbound: true, read: false
      expect(described_class.new.build(user: usertwo)).to eq nil
    end

    specify 'when there is one unread message' do
      user = create :user
      client = create :client, user: user, first_name: "Donald", last_name: "Duck"
      create :message, user: user, client: client, inbound: true, read: false
      expect(described_class.new.build(user: user)).to eq({
        text: "You have 1 unread message from Donald Duck",
        link_to: "/clients/#{client.id}/messages"
      })
    end

    specify 'when there is more than one unread message from the same client' do
      user = create :user
      client = create :client, user: user, first_name: "Donald", last_name: "Duck"
      create :message, user: user, client: client, inbound: true, read: false
      create :message, user: user, client: client, inbound: true, read: false
      expect(described_class.new.build(user: user)).to eq({
        text: "You have 2 unread messages from Donald Duck",
        link_to: "/clients/#{client.id}/messages"
      })
    end

    specify 'when there is more than one unread message from multiple clients' do
      user = create :user
      clientone = create :client, user: user, first_name: "Donald", last_name: "Duck"
      clienttwo = create :client, user: user, first_name: "Donald", last_name: "Duck"
      create :message, user: user, client: clientone, inbound: true, read: false
      create :message, user: user, client: clienttwo, inbound: true, read: false
      expect(described_class.new.build(user: user)).to eq({
        text: "You have 2 unread messages",
        link_to: "/clients"
      })
    end
  end
end
