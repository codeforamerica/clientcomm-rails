class AddInTreatmentGroupToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :in_treatment_group, :boolean, default: false
  end
end
