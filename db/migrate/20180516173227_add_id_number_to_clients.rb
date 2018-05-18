class AddIdNumberToClients < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :id_number, :string
  end
end
