class RemoveColumnsFromClient < ActiveRecord::Migration[5.1]
  def change
    remove_column :clients, :notes, :text
    remove_reference :clients, :client_status, foreign_key: true
    remove_column :clients, :active, :boolean
    remove_column :clients, :has_message_error, :boolean
    remove_column :clients, :has_unread_messages, :boolean
    remove_column :clients, :last_contacted_at, :datetime
  end
end
