class CreateReportingRelationships < ActiveRecord::Migration[5.1]
  def change
    create_table :reporting_relationships do |t|
      t.references :user, foreign_key: true
      t.references :client, foreign_key: true

      t.timestamps
    end
  end
end
