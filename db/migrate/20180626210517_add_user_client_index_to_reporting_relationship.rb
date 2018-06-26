class AddUserClientIndexToReportingRelationship < ActiveRecord::Migration[5.1]
  def change
    add_index :reporting_relationships, %i[client_id user_id]
  end
end
