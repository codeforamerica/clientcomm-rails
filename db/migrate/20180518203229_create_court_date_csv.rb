class CreateCourtDateCSV < ActiveRecord::Migration[5.1]
  def change
    create_table :court_date_csvs do |t|
      t.attachment :file
    end
  end
end
