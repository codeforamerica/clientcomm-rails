class RenameAttachmentToLegacyAttachment < ActiveRecord::Migration[5.1]
  def change
    rename_table :legacy_attachments, :legacy_attachments
  end
end
