class CreateChangeImage < ActiveRecord::Migration[5.1]
  def change
    create_table :change_images do |t|
      t.attachment :file
    end
  end
end
