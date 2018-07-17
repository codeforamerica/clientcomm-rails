require 'rails_helper'

RSpec.describe EventsChannel, type: :channel do
  let(:user) { create :user }

  before do
    stub_connection current_user: user
  end

  subject { subscribe(user_id: user.id) }

  it 'subscribes' do
    subject

    expect(subscription).to be_confirmed
  end

  context 'accessing a channel for a different user' do
    let(:user2) { create :user }

    subject { subscribe(user_id: user2.id) }

    it 'rejects the subscription' do
      subject

      expect(subscription).to be_rejected
    end
  end
end
