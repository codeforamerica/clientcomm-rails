require 'rails_helper'

describe SortClients do
  let(:user) { create :user }

  describe '#clients_list' do
    it 'filters inactive clients, sorts by unread messages, then last_contacted_at or created_at' do
      client3 = create :client, first_name: '5'
      ReportingRelationship.create(
        client: client3,
        user: user,
        has_unread_messages: false,
        created_at: Time.zone.today
      )
      client1 = create :client, first_name: '1'
      ReportingRelationship.create(
        client: client1,
        user: user,
        has_unread_messages: true,
        last_contacted_at: Time.zone.today
      )
      client2 = create :client, first_name: '2'
      ReportingRelationship.create(
        client: client2,
        user: user,
        has_unread_messages: true,
        created_at: Time.zone.today - 5.days
      )
      client4 = create :client, first_name: '6'
      ReportingRelationship.create(
        client: client4,
        user: user,
        has_unread_messages: false,
        last_contacted_at: Time.zone.today - 5.days
      )

      create :client, user: user, active: false

      sorted_clients = described_class.clients_list(user: user)

      expect(sorted_clients).to eq [client1, client2, client3, client4]
    end
  end

  describe '#mass_messages_list' do
    it 'filters inactive clients, sorts by pre-selected, then last_contacted_at or created_at' do
      client3 = create :client, first_name: '5'
      ReportingRelationship.create(
        user: user,
        client: client3,
        created_at: Time.zone.today
      )
      client1 = create :client, first_name: '1'
      ReportingRelationship.create(
        user: user,
        client: client1,
        last_contacted_at: Time.zone.today
      )
      client2 = create :client, first_name: '2'
      ReportingRelationship.create(
        user: user,
        client: client2,
        created_at: Time.zone.today - 5.days
      )
      client4 = create :client, first_name: '6'
      ReportingRelationship.create(
        user: user,
        client: client4,
        last_contacted_at: Time.zone.today - 5.days
      )

      create :client, user: user, active: false

      sorted_clients = described_class.mass_messages_list(user: user, selected_clients: [client1.id, client2.id])

      expect(sorted_clients).to eq [client1, client2, client3, client4]
    end
  end
end
