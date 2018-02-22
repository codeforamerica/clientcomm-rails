class RemoveInTreatmentGroupFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :in_treatment_group, :boolean
  end
end
