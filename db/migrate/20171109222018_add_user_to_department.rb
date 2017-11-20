class AddUserToDepartment < ActiveRecord::Migration[5.1]
  def change
    add_reference :departments, :user, foreign_key: true
  end
end
