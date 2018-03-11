class ChangeUserTreatmentGroupToString < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :treatment_group, :string
  end
end
