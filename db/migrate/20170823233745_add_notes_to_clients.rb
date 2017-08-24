class AddNotesToClients < ActiveRecord::Migration[5.0]
  def change
    add_column :clients, :notes, :text
  end
end
