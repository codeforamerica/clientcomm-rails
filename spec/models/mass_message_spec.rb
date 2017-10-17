require 'rails_helper'

RSpec.describe MassMessage, type: :model do
  it { should validate_presence_of :message }
  it { should validate_presence_of :clients }

  it 'converts client ids to ints' do
    message = MassMessage.new(clients: %w(1 2 3))
    expect(message.clients).to contain_exactly(1,2,3)
  end

  it 'can be instiantiated with nil clients' do
    expect{ MassMessage.new }.to_not raise_error
  end
end
