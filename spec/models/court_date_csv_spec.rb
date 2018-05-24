require 'rails_helper'

RSpec.describe CourtDateCSV, type: :model do
  describe 'paperclip content type validations' do
    it {
      should validate_attachment_content_type(:file)
        .allowing('text/csv')
        .rejecting('png/whatever')
    }
  end
end
