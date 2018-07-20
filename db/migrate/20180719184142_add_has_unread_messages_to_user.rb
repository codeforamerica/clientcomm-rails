class AddHasUnreadMessagesToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :has_unread_messages, :boolean, default: false, null: false
  end
end
