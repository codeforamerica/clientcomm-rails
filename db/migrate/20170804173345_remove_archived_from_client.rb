class RemoveArchivedFromClient < ActiveRecord::Migration[5.0]
  def change
    remove_column :clients, :archived
  end
end
