require 'rails_helper'

describe TextMessage, type: :model do
  it { should validate_presence_of :number_from }
  it { should validate_presence_of :number_to }
  describe 'automatically sets to and from' do
    context 'its inbound' do
      let('message') { create :text_message, inbound: true }

      it 'sets to to department phone' do
        expect(message.number_to).to eq(message.reporting_relationship.user.department.phone_number)
      end
      it 'sets from to client phone' do
        expect(message.number_from).to eq(message.reporting_relationship.client.phone_number)
      end
    end

    context 'its outbound' do
      let('message') { create :text_message, inbound: false }

      it 'sets to to client phone' do
        expect(message.number_to).to eq(message.reporting_relationship.client.phone_number)
      end
      it 'sets from to department phone' do
        expect(message.number_from).to eq(message.reporting_relationship.user.department.phone_number)
      end
    end
  end
end
