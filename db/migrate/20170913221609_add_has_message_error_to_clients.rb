class AddHasMessageErrorToClients < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :has_message_error, :boolean, default: false, null: false
  end
end
