class AddAdminFlagToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :admin, :boolean, default: false

    User.where('email ILIKE ?', '%codeforamerica.org').each do |user|
      user.update!(admin: true)
    end
  end
end
