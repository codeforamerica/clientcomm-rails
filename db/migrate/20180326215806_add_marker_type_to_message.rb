class AddMarkerTypeToMessage < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :marker_type, :int, null: true, default: nil
    add_index :messages, :marker_type
  end
end
