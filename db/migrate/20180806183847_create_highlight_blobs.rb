class CreateHighlightBlobs < ActiveRecord::Migration[5.1]
  def change
    create_table :highlight_blobs do |t|
      t.text :text

      t.timestamps
    end
  end
end
