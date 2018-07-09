require 'rails_helper'

RSpec.describe ChangeImage, type: :model do
  describe 'validations' do
    it { should belong_to :admin_user }

    it {
      should validate_attachment_content_type(:file)
        .allowing('image/png')
        .rejecting('text/whatever')
    }
  end
end
