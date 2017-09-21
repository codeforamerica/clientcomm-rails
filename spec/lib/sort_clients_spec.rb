require 'rails_helper'

describe SortClients do
  let(:user) { create :user }

  it 'filters inactive clients, sorts by unread messages, then last_contacted_at or created_at' do
    client_4 = create :client, first_name: '4', user: user, active: true, has_unread_messages: false, last_contacted_at: Date.today + 5.days
    client_5 = create :client, first_name: '5', user: user, active: true, has_unread_messages: false, created_at: Date.today
    client_1 = create :client, first_name: '1', user: user, active: true, has_unread_messages: true, last_contacted_at: Date.today + 5.days
    client_2 = create :client, first_name: '2', user: user, active: true, has_unread_messages: true, created_at: Date.today
    client_6 = create :client, first_name: '6', user: user, active: true, has_unread_messages: false, last_contacted_at: Date.today - 5.days
    client_3 = create :client, first_name: '3', user: user, active: true, has_unread_messages: true, last_contacted_at: Date.today - 5.days

    create :client, user: user, active: false
    create :client, user: user, active: false

    sorted_clients = described_class.run(user: user)

    expect(sorted_clients).to eq [client_1, client_2, client_3, client_4, client_5, client_6]
  end
end
