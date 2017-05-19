class AddFullNameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :full_name, :string, default: ""
  end
end
