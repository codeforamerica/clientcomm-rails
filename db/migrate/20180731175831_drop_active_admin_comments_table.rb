class DropActiveAdminCommentsTable < ActiveRecord::Migration[5.1]
  def self.up
    drop_table :active_admin_comments
  end

  def self.down
    create_table :active_admin_comments do |t|
      t.string :namespace
      t.text   :body
      t.references :resource, polymorphic: true
      t.references :author, polymorphic: true
      t.timestamps
    end
    add_index :active_admin_comments, [:namespace]
  end
end
