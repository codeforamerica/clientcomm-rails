class Attachment < ApplicationRecord
  belongs_to :message

  attr_reader :media_remote_url
  has_attached_file :media
  validates_attachment_content_type :media, content_type: /video\/.*|audio\/.*|image\/.*|text\/.*|application\/pdf.*/

  def image?
    media_content_type.match?(/image\/.*/) ? true : false
  end
end
