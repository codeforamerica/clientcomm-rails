require 'rails_helper'

describe MessageAlertBuilder do

  describe '#build' do
    specify 'when there are no unread messages' do
      user = create :user
      expect(described_class.new.build(user: user)).to eq nil
    end

    specify 'when there is one unread message' do
      user = create :user
      client = create :client, user: user, first_name: "Donald", last_name: "Duck"
      create :message, user: user, client: client, inbound: true, read: false
      expect(described_class.new.build(user: user)).to eq({
        text: "You have an unread message from Donald Duck",
        link_to: "/clients/#{client.id}/messages"
      })
    end

    specify 'when there is more than one unread message from the same client' do

    end

    specify 'when there is more than one unread message from multiple clients' do
    end
  end
end
