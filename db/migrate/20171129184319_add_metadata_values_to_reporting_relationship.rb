class AddMetadataValuesToReportingRelationship < ActiveRecord::Migration[5.1]
  def change
    add_column :reporting_relationships, :notes, :text
    add_column :reporting_relationships, :last_contacted_at, :datetime
    add_column :reporting_relationships, :has_unread_messages, :boolean, default: false, null: false
    add_column :reporting_relationships, :has_message_error, :boolean, default: false, null: false
    add_reference :reporting_relationships, :client_status, foreign_key: true
  end
end
