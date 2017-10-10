class MakeFullNameNonNullable < ActiveRecord::Migration[5.1]
  def up
    User.where(full_name: nil).each do |user|
      user.update!(full_name: user.email)
    end

    change_column :users, :full_name, :string, null: false, default: nil
  end

  def down
    change_column :users, :full_name, :string, null: true, default: ''
  end
end
