require 'rails_helper'

RSpec.describe ClientsChannel, type: :channel do
  let(:user) { create :user }

  before do
    stub_connection current_user: user
  end

  it 'subscribes' do
    subscribe

    expect(subscription).to be_confirmed
  end
end
