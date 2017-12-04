class AddLastContactedAtToClients < ActiveRecord::Migration[5.0]
  def up
    add_column :clients, :last_contacted_at, :datetime, null: false, default: -> { 'NOW()' }
    add_column :clients, :has_unread_messages, :boolean, null: false, default: false
  end

  def down
    remove_column :clients, :last_contacted_at
    remove_column :clients, :has_unread_messages
  end
end
