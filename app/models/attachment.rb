class Attachment < ApplicationRecord
  belongs_to :message

  attr_reader :media_remote_url
  has_attached_file :media
  validates_attachment_content_type :media, content_type: /video\/.*|audio\/.*|image\/.*|text\/.*|application\/pdf.*/

  # Save attachment content with Paperclip
  def media_remote_url=(url_value)
    self.media = URI.parse(url_value)
    @media_remote_url = url_value
  end

  def image?
    media_content_type.match?(/image\/.*/) ? true : false
  end
end
