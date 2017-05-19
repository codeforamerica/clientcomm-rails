class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.references :client, foreign_key: true
      t.references :user, foreign_key: true
      t.string :body, default: ""
      t.string :number_from, null: false
      t.string :number_to, null: false
      t.boolean :inbound, default: false, null: false
      t.string :twilio_sid
      t.string :twilio_status

      t.timestamps
    end
  end
end
