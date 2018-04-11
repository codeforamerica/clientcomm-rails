class AddNodeIdToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :node_id, :bigint
  end
end
