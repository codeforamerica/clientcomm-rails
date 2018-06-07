class AddCourtDateCSVToMessage < ActiveRecord::Migration[5.1]
  def change
    add_reference :messages, :court_date_csv, foreign_key: { to_table: :court_date_csvs }
  end
end
