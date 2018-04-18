require 'rails_helper'

RSpec.describe MassMessage, type: :model do
  it { should validate_presence_of :message }
  it { should validate_presence_of :reporting_relationships }

  it 'converts client ids to ints' do
    message = MassMessage.new(reporting_relationships: %w(1 2 3))
    expect(message.reporting_relationships).to contain_exactly(1, 2, 3)
  end

  it 'can be instiantiated with nil rrs' do
    expect { MassMessage.new }.to_not raise_error
  end

  describe 'validations' do
    it 'should validate that a message is scheduled in the future' do
      expect(MassMessage.new.past_message?).to be_falsey

      expect(MassMessage.new(send_at: Time.current - 1.day).past_message?).to be_truthy

      expect(MassMessage.new(send_at: Time.current).past_message?).to be_falsey
      expect(MassMessage.new(send_at: Time.current + 5.minutes).past_message?).to be_falsey

      mass_message = MassMessage.new(send_at: Time.current - 1.day)
      mass_message.past_message?
      expect(mass_message.errors[:send_at])
        .to include "You can't schedule a message in the past."
    end
  end
end
