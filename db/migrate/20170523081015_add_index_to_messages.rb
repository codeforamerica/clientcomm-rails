class AddIndexToMessages < ActiveRecord::Migration[5.0]
  def change
    add_index :messages, :twilio_sid
  end
end
