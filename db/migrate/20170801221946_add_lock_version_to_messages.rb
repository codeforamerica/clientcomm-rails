class AddLockVersionToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :lock_version, :integer, default: 0
  end
end
