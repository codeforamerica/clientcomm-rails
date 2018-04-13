class AddNodeIdsToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :node_client_id, :bigint
    add_column :clients, :node_comm_id, :bigint
  end
end
