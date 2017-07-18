class RemoveBirthDateFromClients < ActiveRecord::Migration[5.0]
  def change
    remove_column :clients, :birth_date
  end
end
