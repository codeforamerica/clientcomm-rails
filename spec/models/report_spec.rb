require 'rails_helper'

RSpec.describe Report, type: :model do
  it { should belong_to :department }

  describe 'validations' do
    it { should validate_presence_of :email }
  end

  describe 'users' do
    let(:department) { create :department }
    let(:active_users) { create_list :user, 5, department: department }
    let(:inactive_users) { create_list :user, 5, department: department, active: false }
    let(:report) { create :report, department: department }

    it 'returns active users' do
      expect(report.users).to match_array(active_users)
    end
  end
end
