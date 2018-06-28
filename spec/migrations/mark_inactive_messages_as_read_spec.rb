require 'rails_helper.rb'
require_relative '../../db/migrate/20180627210514_mark_inactive_messages_as_read.rb'

describe MarkInactiveMessagesAsRead do
  let!(:rr) { create :reporting_relationship, active: false }

  after do
    ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), @current_migration
    Message.reset_column_information
  end

  describe '#up' do
    before do
      @current_migration = ActiveRecord::Migrator.current_version
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180627173300
      Message.reset_column_information
    end

    subject do
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180627210514
      Message.reset_column_information
    end

    it 'marks unread message as read' do
      Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: false,
        inbound: true,
        send_at: Time.zone.now,
        type: 'TextMessage',
        number_from: rr.client.phone_number,
        number_to: rr.user.department.phone_number
      )

      subject

      expect(rr.messages.where(read: false)).to be_empty
    end

    context 'rr is active' do
      let!(:rr) { create :reporting_relationship, active: true }

      it 'does not mark unread message as read' do
        message = Message.create!(
          reporting_relationship_id: rr.id,
          original_reporting_relationship_id: rr.id,
          read: false,
          inbound: true,
          send_at: Time.zone.now,
          type: 'TextMessage',
          number_from: rr.client.phone_number,
          number_to: rr.user.department.phone_number
        )

        subject

        expect(rr.messages.where(read: false)).to contain_exactly(message)
      end
    end

    context 'the client has a second, active rr' do
      let!(:user2) { create :user, department: rr.user.department }
      let!(:rr2) { create :reporting_relationship, client: rr.client, user: user2, active: true }

      it 'marks only the unread message on the inactive rr as read' do
        Message.create!(
          reporting_relationship_id: rr.id,
          original_reporting_relationship_id: rr.id,
          read: false,
          inbound: true,
          send_at: Time.zone.now,
          type: 'TextMessage',
          number_from: rr.client.phone_number,
          number_to: rr.user.department.phone_number
        )

        message2 = Message.create!(
          reporting_relationship_id: rr2.id,
          original_reporting_relationship_id: rr2.id,
          read: false,
          inbound: true,
          send_at: Time.zone.now,
          type: 'TextMessage',
          number_from: rr2.client.phone_number,
          number_to: rr2.user.department.phone_number
        )

        subject

        expect(rr.messages.where(read: false)).to be_empty
        expect(rr2.messages.where(read: false)).to contain_exactly(message2)
      end
    end
  end
end
