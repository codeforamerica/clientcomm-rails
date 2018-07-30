class AddIndexToMessagesSendAt < ActiveRecord::Migration[5.1]
  def change
    add_index :messages, :send_at
  end
end
