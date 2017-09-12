class AddActiveToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :active, :boolean, null: false, default: true
  end
end
