require 'rails_helper'

describe MetricsGenerator do
  context 'generate metrics report' do
    subject { described_class.generate }

    it 'outputs total number of case managers' do
      create_list :user, 3
      expect(subject).to include 'Case managers: 3'
    end

    it 'outputs the number of active and total clients' do
      create_list :client, 50, active: true
      create_list :client, 10, active: false
      expect(subject).to include 'Active Clients: 50'
      expect(subject).to include 'Total Clients: 60'
    end

    it 'outputs number of clients who received their first message in the last week' do
      client1 = create :client
      client2 = create :client
      client3 = create :client
      client4 = create :client
      client5 = create :client

      create :message, client: client1, created_at: Time.now

      create :message, client: client2, created_at: Time.now.yesterday
      create :message, client: client2, created_at: Time.now

      create :message, client: client3, created_at: Time.now - 5.days
      create :message, client: client3, created_at: Time.now.yesterday
      create :message, client: client3, created_at: Time.now

      create :message, client: client4, created_at: Time.now.last_month
      create :message, client: client4, created_at: Time.now.yesterday

      create :message, client: client5, created_at: Time.now.last_year
      create :message, client: client5, created_at: Time.now.last_month
      create :message, client: client5, created_at: Time.now.yesterday


      expect(subject).to include 'New conversations in last week: 3'
    end

    it 'outputs average number of messages per conversation' do
      client1 = create :client
      client2 = create :client
      client3 = create :client

      create_list :message, 30, client: client1
      create_list :message, 15, client: client2
      create_list :message, 10, client: client3


      expect(subject).to include 'Average number of messages per conversation: 18'
    end

    it 'outputs the total number of messages sent/received' do
      create_list :message, 55, inbound: true
      create_list :message, 32, inbound: false
      expect(subject).to include 'Total number of messages sent/received: 87'
      expect(subject).to include 'Total number of messages received: 55'
      expect(subject).to include 'Total number of messages sent: 32'
    end
  end
end
