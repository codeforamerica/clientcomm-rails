class CreateTemplates < ActiveRecord::Migration[5.1]
  def up
    create_table :templates do |t|
      t.string :title
      t.text :body
    end
  end

  def down
    drop_table :templates
  end
end
