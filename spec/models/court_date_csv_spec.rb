require 'rails_helper'

RSpec.describe CourtDateCSV, type: :model do
  describe 'validations' do
    it { should belong_to :admin_user }

    it {
      should validate_attachment_content_type(:file)
        .allowing('text/csv')
        .rejecting('png/whatever')
    }
  end
end
