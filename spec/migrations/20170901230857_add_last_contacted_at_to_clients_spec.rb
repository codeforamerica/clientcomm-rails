require 'rails_helper'
require './db/migrate/20170901230857_add_last_contacted_at_to_clients'

describe AddLastContactedAtToClients do
  let(:my_migration_version) { 20170901230857 }
  let(:previous_migration_version) { 20170823233745 }

  before do
    ActiveRecord::Migrator.migrate ['db/migrate'], previous_migration_version

    @client = create :client
  end

  describe '#up' do
    subject { ActiveRecord::Migrator.migrate ['db/migrate'], my_migration_version }

    context 'client has no messages' do
      it 'last_contacted_at is created at if no messages' do
        subject

        expect(Client.first.last_contacted_at).to be_within(0.1.seconds).of @client.updated_at
      end
    end

    context 'client has messages' do
      before do
        travel_to 5.days.ago do
          create :message, client: @client, send_at: Time.now
          create :message, client: @client, send_at: Time.now + 1.days
        end

        travel_to Time.now + 10.days do
          create :message, client: @client, send_at: Time.now
        end

        @latest_message = create :message, client: @client, send_at: Time.now
      end

      it 'last contact is date of first past message' do
        subject

        expect(Client.first.last_contacted_at).to be_within(0.1.seconds).of @latest_message.send_at
      end
    end

    context 'client has unread messages' do
      before do
        travel_to 10.days.ago do
          create :message, client: @client, inbound: true, read: true, send_at: 1.days.from_now
          create :message, client: @client, inbound: true, read: false, send_at: 2.days.from_now
          create :message, client: @client, inbound: true, read: true, send_at: 3.days.from_now
          create :message, client: @client, inbound: true, read: false, send_at: 4.days.from_now
          create :message, client: @client, inbound: false, read: true, send_at: 5.days.from_now
        end
      end

      it 'makes has_unread_messages true if any message is not read' do
        subject

        expect(Client.first.has_unread_messages).to eq true
      end
    end

    context 'client has no unread messages' do
      before do
        create :message, client: @client, read: true
        create :message, client: @client, read: true
        create :message, client: @client, read: true
      end

      it 'client has_unread_messages is false if all messsages are read' do
        subject

        expect(Client.first.has_unread_messages).to eq false
      end
    end
  end
end