class AddTemplatesRefToUsers < ActiveRecord::Migration[5.1]
  def change
    add_reference :templates, :user, foreign_key: true
  end
end
