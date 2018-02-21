class AddIconColorToClientStatus < ActiveRecord::Migration[5.1]
  def change
    add_column :client_statuses, :icon_color, :string, :limit => 7
  end
end
