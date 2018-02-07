class AddTransferMarkerToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :transfer_marker, :bool, default: false
  end
end
