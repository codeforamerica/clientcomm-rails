class AddCourtDateToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :next_court_date_at, :date, null: true
  end
end
