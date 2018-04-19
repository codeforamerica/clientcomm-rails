class AddCategoryToReportingRelationship < ActiveRecord::Migration[5.1]
  def change
    add_column :reporting_relationships, :category, :string
  end
end
