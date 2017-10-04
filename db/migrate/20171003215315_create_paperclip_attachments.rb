class CreatePaperclipAttachments < ActiveRecord::Migration[5.1]
  def self.up
    create_table :attachments do |t|
      t.references :message, foreign_key: true, null: false
      t.attachment :media
    end
  end

  def self.down
    drop_table :attachments
  end
end
