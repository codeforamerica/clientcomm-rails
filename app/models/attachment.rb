class Attachment < ApplicationRecord
  belongs_to :message

  has_attached_file :media
  validates_attachment_content_type :media, content_type: /video\/.*|audio\/.*|image\/.*|text\/.*|application\/pdf.*/

	before_save :extract_dimensions
	serialize :dimensions, Array

  def update_media(url:)
    self.media = open(url,
                      http_basic_authentication: [ENV['TWILIO_ACCOUNT_SID'],
                                                  ENV['TWILIO_AUTH_TOKEN']])
  end

  def image?
    media_content_type.match?(/image\/.*/) ? true : false
  end

	def extract_dimensions
		return unless image?
		tempfile = media.queued_for_write[:original]
		unless tempfile.nil?
			geometry = Paperclip::Geometry.from_file(tempfile)
			self.dimensions = [geometry.width.to_i, geometry.height.to_i]
		end
	end
end
