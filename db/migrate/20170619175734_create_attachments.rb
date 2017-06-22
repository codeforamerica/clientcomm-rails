class CreateAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :attachments do |t|
      t.string :url, null:false
      t.string :content_type
      t.references :message, foreign_key: true, null: false
      t.integer :height
      t.integer :width
    end
  end
end
