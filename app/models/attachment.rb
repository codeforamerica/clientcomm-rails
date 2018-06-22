class Attachment < ApplicationRecord
  belongs_to :message

  attr_reader :media_remote_url
  has_attached_file :media
  do_not_validate_attachment_file_type :media

  # Save attachment content with Paperclip
  def media_remote_url=(url_value)
    self.media = URI.parse(url_value)
    @media_remote_url = url_value
  end

  def image?
    media_content_type.match?(/image\/.*/) ? true : false
  end
end
