class AddAdminUserToChangeImage < ActiveRecord::Migration[5.1]
  def change
    add_reference :change_images, :admin_user, foreign_key: { to_table: :admin_users }, null: false, default: 1
  end
end
