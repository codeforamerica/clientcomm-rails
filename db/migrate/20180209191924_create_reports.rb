class CreateReports < ActiveRecord::Migration[5.1]
  def change
    create_table :reports do |t|
      t.string :email, null: false
      t.references :department, foreign_key: true, null: false

      t.timestamps
    end
  end
end
