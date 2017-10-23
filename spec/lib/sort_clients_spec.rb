require 'rails_helper'

describe SortClients do
  let(:user) { create :user }

  describe '#clients_list' do
    it 'filters inactive clients, sorts by unread messages, then last_contacted_at or created_at' do
      client_3 = create :client, first_name: '5', user: user, active: true, has_unread_messages: false, created_at: Date.today
      client_1 = create :client, first_name: '1', user: user, active: true, has_unread_messages: true, last_contacted_at: Date.today
      client_2 = create :client, first_name: '2', user: user, active: true, has_unread_messages: true, created_at: Date.today - 5.days
      client_4 = create :client, first_name: '6', user: user, active: true, has_unread_messages: false, last_contacted_at: Date.today - 5.days

      create :client, user: user, active: false

      sorted_clients = described_class.clients_list(user: user)

      expect(sorted_clients).to eq [client_1, client_2, client_3, client_4]
    end
  end

  describe '#mass_messages_list' do
    it 'filters inactive clients, sorts by pre-selected clients, then last_contacted_at or created_at' do
      client_3 = create :client, first_name: '5', user: user, active: true, created_at: Date.today
      client_1 = create :client, first_name: '1', user: user, active: true, last_contacted_at: Date.today
      client_2 = create :client, first_name: '2', user: user, active: true, created_at: Date.today - 5.days
      client_4 = create :client, first_name: '6', user: user, active: true, last_contacted_at: Date.today - 5.days

      create :client, user: user, active: false

      sorted_clients = described_class.mass_messages_list(user: user, selected_clients: [client_1.id, client_2.id])

      expect(sorted_clients).to eq [client_1, client_2, client_3, client_4]
    end
  end
end
