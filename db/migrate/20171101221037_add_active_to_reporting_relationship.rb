class AddActiveToReportingRelationship < ActiveRecord::Migration[5.1]
  def change
    add_column :reporting_relationships, :active, :boolean, default: true, null: false
  end
end
