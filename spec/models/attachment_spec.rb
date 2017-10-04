require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'relationships' do
    it { should belong_to :message }
  end
end
