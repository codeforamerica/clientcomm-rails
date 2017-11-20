class CreateDepartments < ActiveRecord::Migration[5.1]
  def change
    create_table :departments do |t|
      t.string :name
      t.string :phone_number

      t.timestamps
    end
  end
end
