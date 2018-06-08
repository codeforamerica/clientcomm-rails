require 'rails_helper'

describe TextMessage, type: :model do
  it { should validate_presence_of :number_from }
  it { should validate_presence_of :number_to }

  describe 'automatically sets number_to and number_from' do
    context 'the message is inbound' do
      let('message') { create :text_message, inbound: true }

      it 'sets number_to to department phone' do
        expect(message.number_to).to eq(message.reporting_relationship.user.department.phone_number)
      end
      it 'sets number_from to client phone' do
        expect(message.number_from).to eq(message.reporting_relationship.client.phone_number)
      end
    end

    context 'the message is outbound' do
      let('message') { create :text_message, inbound: false }

      it 'sets number_to to client phone' do
        expect(message.number_to).to eq(message.reporting_relationship.client.phone_number)
      end
      it 'sets number_from to department phone' do
        expect(message.number_from).to eq(message.reporting_relationship.user.department.phone_number)
      end
    end
  end
end
