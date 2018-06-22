class Attachment < ApplicationRecord
  belongs_to :message

  has_attached_file :media
  validates_attachment_content_type :media, content_type: /video\/.*|audio\/.*|image\/.*|text\/.*|application\/pdf.*/

  def media_file(url)
    self.media = open(url,
                      http_basic_authentication: [ENV['TWILIO_ACCOUNT_SID'],
                                                  ENV['TWILIO_AUTH_TOKEN']])
  end

  def image?
    media_content_type.match?(/image\/.*/) ? true : false
  end
end
