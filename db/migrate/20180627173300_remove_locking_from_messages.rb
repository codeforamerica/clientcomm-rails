class RemoveLockingFromMessages < ActiveRecord::Migration[5.1]
  def change
    remove_column :messages, :lock_version, :interger
  end
end
