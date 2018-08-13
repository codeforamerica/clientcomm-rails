class DropTemplates < ActiveRecord::Migration[5.1]
  def up
    drop_table :templates
  end

  def down
    create_table :templates do |t|
      t.string :title
      t.text :body
    end
  end
end
