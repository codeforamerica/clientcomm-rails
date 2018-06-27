require 'rails_helper.rb'
require_relative '../../db/migrate/20180627210514_mark_inactive_messages_as_read.rb'

describe MarkInactiveMessagesAsRead do
  let(:rr) { create :reporting_relationship, active: false }

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

    it 'marks unread messages as read' do
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
      let(:rr) { create :reporting_relationship, active: true }
      it 'marks unread messages as read' do
        text_message = Message.create!(
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
        expect(rr.messages.where(read: false)).to contain_exactly(text_message)
      end
    end
  end
end
