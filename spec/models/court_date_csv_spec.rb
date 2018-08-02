require 'rails_helper'

RSpec.describe CourtDateCSV, type: :model do
  describe 'validations' do
    it { should belong_to :user }

    it {
      should validate_attachment_content_type(:file)
        .allowing('text/csv')
        .rejecting('png/whatever')
    }
  end
end
