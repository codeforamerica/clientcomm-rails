class AddDeskPhoneNumberToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :desk_phone_number, :string, null: true
  end
end
