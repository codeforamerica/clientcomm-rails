class RenameAttachmentToLegacyAttachment < ActiveRecord::Migration[5.1]
  def change
    rename_table :attachments, :legacy_attachments
  end
end
