class AddAdminUserToCourtDateCsv < ActiveRecord::Migration[5.1]
  def change
    add_reference :court_date_csvs, :admin_user, foreign_key: { to_table: :admin_users }, null: false, default: 1
  end
end
