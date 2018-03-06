class AddAutoreplyToDepartment < ActiveRecord::Migration[5.1]
  def change
    add_column :departments, :unclaimed_response, :text
  end
end
