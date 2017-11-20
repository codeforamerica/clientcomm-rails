require 'rails_helper'
require './db/migrate/20171107212003_move_active_from_clients_to_reporting_relationships'

describe MoveActiveFromClientsToReportingRelationships do
  let(:my_migration_version) { 20171107212003 }
  let(:previous_migration_version) { 20171101221037 }

  before do
    ActiveRecord::Migrator.migrate ['db/migrate'], previous_migration_version

    @orphan_client = create :client, user: nil

    @user = create :user
    @all_clients = []
    @active_clients = []
    10.times do
      client = create(:client, user_id: @user.id, user: nil)
      client.update_attribute('active', true)
      @active_clients << client
      @all_clients << client
    end
    @inactive_clients = []
    10.times do
      client = create(:client, user_id: @user.id, user: nil)
      client.update_attribute('active', false)
      @inactive_clients << client
      @all_clients << client
    end
  end

  describe '#up' do
    subject { ActiveRecord::Migrator.migrate ['db/migrate'], my_migration_version }

    context 'clients exist with active values set' do
      it 'migrates active values from client to reporting relationship' do
        subject

        expect(@orphan_client.reporting_relationships.count).to eq(0)

        have_relationships = @all_clients.all?{ |client| client.reporting_relationships.any? }
        expect(have_relationships).to eq(true)

        all_active = @active_clients.all?{ |client| client.reporting_relationships.all?(&:active) }
        expect(all_active).to eq(true)


        all_inactive = @inactive_clients.all?{ |client| client.reporting_relationships.none?(&:active) }
        expect(all_inactive).to eq(true)
      end
    end
  end
end
