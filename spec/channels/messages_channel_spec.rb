require 'rails_helper'

RSpec.describe MessagesChannel, type: :channel do
  let(:user) { create :user }
  let(:client) { create :client, user: user }

  before do
    stub_connection current_user: user
  end

  subject { subscribe(client_id: client.id) }

  it 'subscribes' do
    subject

    expect(subscription).to be_confirmed
  end

  context 'accessing clients that do not belong to the current_user' do
    let(:user2) { create :user }

    before do
      stub_connection current_user: user2
    end

    it 'rejects the subscription' do
      subject

      expect(subscription).to be_rejected
    end
  end
end
