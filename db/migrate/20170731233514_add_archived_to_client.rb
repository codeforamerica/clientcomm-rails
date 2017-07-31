class AddArchivedToClient < ActiveRecord::Migration[5.0]
  def change
    add_column :clients, :archived, :boolean, default: false
  end
end
