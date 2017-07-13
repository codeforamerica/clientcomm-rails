class AddSendDateToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :send_date, :datetime
  end
end
