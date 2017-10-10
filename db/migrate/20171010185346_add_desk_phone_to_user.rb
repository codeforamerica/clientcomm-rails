class AddDeskPhoneToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :desk_phone, :string, null: true
  end
end
