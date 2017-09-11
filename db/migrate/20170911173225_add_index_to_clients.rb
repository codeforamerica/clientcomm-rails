class AddIndexToClients < ActiveRecord::Migration[5.0]
  def change
    add_index :clients, :phone_number, unique: true
  end
end
