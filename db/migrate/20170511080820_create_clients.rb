class CreateClients < ActiveRecord::Migration[5.0]
  def change
    create_table :clients do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :birth_date
      t.string :phone_number
      t.boolean :active, default: true, null: false

      t.timestamps null: false
    end
  end
end
