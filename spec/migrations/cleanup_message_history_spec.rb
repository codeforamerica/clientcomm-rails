require 'rails_helper.rb'
require_relative '../../db/migrate/20180816222016_cleanup_message_history.rb'

describe CleanupMessageHistory do
  let(:rr) { create :reporting_relationship }

  after do
    ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), @current_migration
    Message.reset_column_information
  end

  describe '#up' do
    before do
      @current_migration = ActiveRecord::Migrator.current_version
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180816181102
      Message.reset_column_information
    end

    subject do
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180816222016
      Message.reset_column_information
    end

    it 'marks messages with twilio_sid as sent' do
      text_message = TextMessage.create!(
        body: 'test',
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        send_at: Time.zone.now - 1.day,
        sent: false,
        twilio_sid: 'sid',
        inbound: false
      )
      subject
      expect(text_message.reload.sent).to eq(true)
    end

    it 'marks messages with twilio_sid as undelivered' do
      text_message = TextMessage.create!(
        body: 'test',
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        send_at: Time.zone.now - 1.day,
        sent: false,
        twilio_sid: nil,
        inbound: false
      )
      subject
      expect(text_message.reload.twilio_status).to eq('undelivered')
    end

    it 'skips messages in future' do
      text_message = TextMessage.create!(
        body: 'test',
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        send_at: Time.zone.now,
        sent: false,
        twilio_sid: nil,
        inbound: false
      )
      copy_text_message = text_message
      subject
      expect(text_message.reload).to eq(copy_text_message)
    end
  end
end
