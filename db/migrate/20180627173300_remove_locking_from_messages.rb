class RemoveLockingFromMessages < ActiveRecord::Migration[5.1]
  def change
    remove_column :messages, :lock_version, :integer
  end
end
