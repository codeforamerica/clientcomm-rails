require 'rails_helper'

RSpec.describe ReportingRelationship, type: :model do
  it { should belong_to :user }
  it { should belong_to :client }
  it { should belong_to :client_status }
  it { should have_one(:department).through(:user) }

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
          expect(rr.errors.added?(:client, :existing_dept_relationship, user_full_name: user1.full_name))
            .to eq true
        end

        context 'the reporting relationships itself is inactive' do
          it 'is valid' do
            department = create :department
            user1 = create :user, department: department
            user2 = create :user, department: department
            client = create :client, user: user1

            rr = ReportingRelationship.new(
              user: user2,
              client: client,
              active: false
            )

            expect(rr).to be_valid
          end
        end
      end
    end

    describe 'Category' do
      it { should validate_inclusion_of(:category).in_array(ReportingRelationship::CATEGORIES.keys) }
    end
  end

  describe '#deactivate' do
    let(:rr) { create :reporting_relationship, active: true }
    subject do
      rr.deactivate
    end
    it 'deactivates rr' do
      subject
      expect(rr).to_not be_active
    end
    context 'has scheduled messages' do
      before do
        create_list :text_message, 5, reporting_relationship: rr, send_at: Time.zone.now + 1.day
      end
      it 'marks messages as read' do
        subject
        expect(rr.reload.has_unread_messages).to eq(false)
        expect(rr.messages.unread).to be_empty
      end
      it 'deletes scheduled messages' do
        subject
        expect(rr.messages.scheduled).to be_empty
      end
    end
  end

  describe '#transter_to' do
    let(:dept) { create :department }
    let(:old_user) { create :user, department: dept }
    let(:new_user) { create :user, department: dept }
    let(:client) { create :client, user: old_user }
    let(:rr) { ReportingRelationship.find_by(user: old_user, client: client) }
    let!(:scheduled_messages) { create_list :text_message, 5, reporting_relationship: rr, send_at: Time.zone.now + 1.day }
    let(:old_reporting_relationship) { ReportingRelationship.find_by(user: old_user, client: client) }
    let(:new_reporting_relationship) { ReportingRelationship.find_or_initialize_by(user_id: new_user.id, client_id: client.id) }
    before do
      rr.update!(has_unread_messages: true)
    end
    subject do
      old_reporting_relationship.transfer_to(new_reporting_relationship)
    end

    it 'transfers client to user' do
      subject

      expect(old_reporting_relationship.reload).to_not be_active
      expect(new_reporting_relationship.reload).to be_active
      expect(old_user.reload.has_unread_messages).to eq(false)
    end

    it 'transfers creates transfer markers' do
      expect(Message).to receive(:create_transfer_markers).with(sending_rr: old_reporting_relationship, receiving_rr: new_reporting_relationship)
      subject
    end

    it 'transfers scheduled messages' do
      subject
      expect(old_user.messages.scheduled.count).to eq(0)
      expect(new_user.messages.scheduled).to contain_exactly(*scheduled_messages)
    end

    context 'the sending user is the unclaimed user' do
      let!(:messages) { create_list :text_message, 5, reporting_relationship: rr }

      before do
        dept.update(unclaimed_user: old_user)
      end

      it 'transfers all messages' do
        subject
        expect(old_user.messages.messages.count).to eq(0)
        expect(new_user.messages.messages).to include(*messages)
      end
    end
    context 'has client statuses' do
      let!(:status) { create :client_status, department: dept }

      before do
        old_reporting_relationship.client_status = status
        old_reporting_relationship.save!
      end

      it 'transfers client statuses' do
        subject
        old_reporting_relationship.reload
        new_reporting_relationship.reload
        expect(old_reporting_relationship.client_status).to eq(status)
        expect(new_reporting_relationship.client_status).to eq(status)
      end
    end
  end
end
