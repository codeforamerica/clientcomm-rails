class AddNextCourtDateSetByUserToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :next_court_date_set_by_user, :boolean, default: false
  end
end
