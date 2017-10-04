class MigrateOldAttachments < ActiveRecord::Migration[5.1]
  def up
    puts Rails.application.config.paperclip_defaults
    LegacyAttachment.all.each do |old_attachment|
      new_attachment = Attachment.new
      new_attachment.media_remote_url = old_attachment.url
      new_attachment.message_id = old_attachment.message_id
      new_attachment.save!
    end

    drop_table :legacy_attachments
  end
end
