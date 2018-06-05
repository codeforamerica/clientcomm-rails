class CourtDateCSV < ApplicationRecord
  has_attached_file :file
  belongs_to :admin_user
  validates_attachment_content_type :file, content_type: %r{text\/.*}
end
