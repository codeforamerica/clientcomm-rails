class AddTreatmentGroupToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :treatment_group, :text
  end
end
