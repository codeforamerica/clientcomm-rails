class Attachment < ApplicationRecord
  belongs_to :message

  has_attached_file :media
  validates_attachment_content_type :media, content_type: /video\/.*|audio\/.*|image\/.*|text\/.*|application\/pdf.*/
	serialize :dimensions, Array

  def image?
    media_content_type.match?(/image\/.*/) ? true : false
  end
end

class AddDimensionsToAttachments < ActiveRecord::Migration[5.1]
  def up
    add_column :attachments, :dimensions, :string
    Attachment.find_each(batch_size: 50).with_index do |att, i|
      next unless att.image?
      path = "/tmp/#{ i }"
      att.media.copy_to_local_file(:original, path)
      f = open(path)
      geometry = Paperclip::Geometry.from_file(f)
      att.dimensions =  [geometry.width.to_i, geometry.height.to_i]
			att.save!
    end
  end

  def down
    remove_column :attachments, :dimensions, :string
  end
end
