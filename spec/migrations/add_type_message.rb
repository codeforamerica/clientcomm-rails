require 'rails_helper.rb'
require_relative '../../db/migrate/20180515185335_add_type_to_messages.rb'

describe AddTypeToMessages do
  let(:rr) { create :reporting_relationship }

  after do
    ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), @current_migration
    Message.reset_column_information
  end

  describe '#up' do
    before do
      @current_migration = ActiveRecord::Migrator.current_version
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180507185215
      Message.reset_column_information
    end

    subject do
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180515185335
      Message.reset_column_information
    end

    it 'messages have proper values on type' do
      text_message = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: true,
        send_at: Time.zone.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number,
        marker_type: nil
      )
      transfer_marker = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: true,
        send_at: Time.zone.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number,
        marker_type: 0
      )
      client_edit_marker = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: true,
        send_at: Time.zone.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number,
        marker_type: 1
      )
      court_reminder = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: true,
        send_at: Time.zone.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number,
        marker_type: 2
      )

      subject

      expect(text_message.reload.type).to eq('TextMessage')
      expect(transfer_marker.reload.type).to eq('TransferMarker')
      expect(client_edit_marker.reload.type).to eq('ClientEditMarker')
      expect(court_reminder.reload.type).to eq('CourtReminder')
    end
  end

  describe '#down' do
    before do
      @current_migration = ActiveRecord::Migrator.current_version
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180507185215
      Message.reset_column_information
    end

    subject do
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180314000756
      Message.reset_column_information
    end

    it 'messages have proper values on marker_type' do
      text_message = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: true,
        send_at: Time.zone.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number,
        type: 'TextMessage'
      )
      transfer_marker = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: true,
        send_at: Time.zone.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number,
        type: 'TransferMarker'
      )
      client_edit_marker = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: true,
        send_at: Time.zone.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number,
        type: 'ClientEditMarker'
      )
      court_reminder = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: true,
        send_at: Time.zone.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number,
        type: 'CourtReminder'
      )

      subject

      expect(text_message.reload.type).to eq(nil)
      expect(transfer_marker.reload.type).to eq(0)
      expect(client_edit_marker.reload.type).to eq(1)
      expect(court_reminder.reload.type).to eq(2)
    end
  end
end
