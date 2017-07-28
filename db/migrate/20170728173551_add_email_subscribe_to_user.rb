class AddEmailSubscribeToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :email_subscribe, :boolean, default: true
  end
end
