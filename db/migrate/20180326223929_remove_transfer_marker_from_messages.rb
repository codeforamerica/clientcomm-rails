class RemoveTransferMarkerFromMessages < ActiveRecord::Migration[5.1]
  def change
    remove_column :messages, :transfer_marker, :boolean, default: false
  end
end
