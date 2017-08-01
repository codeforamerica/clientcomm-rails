class AddSentToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :sent, :boolean, default: false
  end
end
