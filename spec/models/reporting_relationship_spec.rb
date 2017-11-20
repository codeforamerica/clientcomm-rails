require 'rails_helper'

RSpec.describe ReportingRelationship, type: :model do
  it { should belong_to :user }
  it { should belong_to :client }

  describe 'Validations' do
    it { should validate_presence_of :user }
    it { should validate_presence_of :client }
    it { should_not allow_value(nil).for :active }

    describe 'Client' do
      context 'An identical relationship' do
        let(:user) { create :user }
        let(:client) { create :client, user: user }

        it 'is invalid' do
          rr = ReportingRelationship.new(
            user: user,
            client: client
          )

          expect(rr).to_not be_valid
          expect(rr.errors.added?(:client, :taken)).to eq true
        end
      end

      context 'A relationship within the same department' do
        it 'is invalid' do
          department = create :department
          user1 = create :user, department: department
          user2 = create :user, department: department
          client = create :client, user: user1

          rr = ReportingRelationship.new(
            user: user2,
            client: client
          )

          expect(rr).to_not be_valid
          expect(rr.errors.added?(:client, :existing_dept_relationship))
            .to eq true
        end
      end
    end
  end
end
