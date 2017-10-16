class RenameUserDeskPhoneNumberToPhoneNumber < ActiveRecord::Migration[5.1]
  def change
    rename_column :users, :desk_phone_number, :phone_number
  end
end
