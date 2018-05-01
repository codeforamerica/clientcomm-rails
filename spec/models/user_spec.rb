require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create :user }
  let!(:client) { create :client, user: user }
  let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
  let!(:message) { create :message, reporting_relationship: rr }

  it { should belong_to :department }
  it { should have_many(:clients).through(:reporting_relationships) }
  it { should have_many :messages }

  describe 'normalizing' do
    let(:input_phone_number) { '(760) 555-7890' }
    let(:normalized_phone_number) { '+17605557890' }

    it 'formats the phone number' do
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: input_phone_number)
        .and_return(normalized_phone_number)

      user = create :user, phone_number: input_phone_number, department: nil
      expect(user.reload.phone_number).to eq(normalized_phone_number)
    end
  end

  describe 'scoping' do
    let(:inactive_user) { create :user, department: user.department }

    before do
      ReportingRelationship.create(user: inactive_user, client: client, active: false)
    end

    it 'only shows active users' do
      expect(client.users.active_rr).to include(user)
      expect(client.users.active_rr).to_not include(inactive_user)
    end
  end

  describe 'validations' do
    it { should validate_presence_of :full_name }

    it 'validates correctness of phone_number' do
      bad_number = '(212) 55-5236'
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: bad_number)
        .and_raise(SMSService::NumberNotFound)

      new_user = build(:user, phone_number: bad_number, department: nil)
      expect(new_user.valid?).to eq(false)
      expect(new_user.errors.keys).to contain_exactly(:phone_number)
    end

    it 'does not validate correctness of phone_number if phone number unchanged' do
      user = create :user
      allow(SMSService.instance).to receive(:number_lookup)
      user.update!(full_name: 'some other name')
      expect(SMSService.instance).to_not have_received(:number_lookup)
    end

    it 'cannot be inactive with active reporting relationships' do
      user.active = false
      expect(user.valid?).to eq(false)
      expect(user.errors.keys).to contain_exactly(:active)
    end

    it 'cannot be transferred into a department with conflicting reporting relationships' do
      other_department = create :department
      other_user = create :user, department: other_department
      other_user.clients << client

      user.update(department: other_department)
      expect(user.valid?).to eq(false)
    end
  end

  describe 'scopes' do
    describe 'active' do
      let!(:user_active) { create :user }
      let!(:user_inactive) { create :user, active: false }

      it 'only returns users that are active' do
        expect(User.all.active).to include user_active
        expect(User.all.active).to_not include user_inactive
      end
    end
  end
  describe '#active_reporting_relationships' do
    it 'filters inactive clients, sorts by unread messages, then last_contacted_at or created_at' do
      rr.active = false
      rr.save!
      client3 = create :client, first_name: '5'
      rr3 = ReportingRelationship.create(
        client: client3,
        user: user,
        has_unread_messages: false,
        created_at: Time.zone.today
      )
      client1 = create :client, first_name: '1'
      rr1 = ReportingRelationship.create(
        client: client1,
        user: user,
        has_unread_messages: true,
        last_contacted_at: Time.zone.today
      )
      client2 = create :client, first_name: '2'
      rr2 = ReportingRelationship.create(
        client: client2,
        user: user,
        has_unread_messages: true,
        created_at: Time.zone.today - 5.days
      )
      client4 = create :client, first_name: '6'
      rr4 = ReportingRelationship.create(
        client: client4,
        user: user,
        has_unread_messages: false,
        last_contacted_at: Time.zone.today - 5.days
      )

      create :client, user: user, active: false

      sorted_clients = user.active_reporting_relationships

      expect(sorted_clients).to eq [rr1, rr2, rr3, rr4]
    end
  end
  describe '#mass_messages_list' do
    it 'filters inactive clients, sorts by pre-selected, then last_contacted_at or created_at' do
      rr.active = false
      rr.save!
      client3 = create :client, first_name: '5'
      rr3 = ReportingRelationship.create(
        user: user,
        client: client3,
        created_at: Time.zone.today
      )
      client1 = create :client, first_name: '1'
      rr1 = ReportingRelationship.create(
        user: user,
        client: client1,
        last_contacted_at: Time.zone.today
      )
      client2 = create :client, first_name: '2'
      rr2 = ReportingRelationship.create(
        user: user,
        client: client2,
        created_at: Time.zone.today - 5.days
      )
      client4 = create :client, first_name: '6'
      rr4 = ReportingRelationship.create(
        user: user,
        client: client4,
        last_contacted_at: Time.zone.today - 5.days
      )

      create :client, user: user, active: false

      sorted_clients = user.active_reporting_relationships_with_selection(selected_reporting_relationships: [rr1.id, rr2.id])

      expect(sorted_clients).to eq [rr1, rr2, rr3, rr4]
    end
  end
  describe '#relationships_with_statuses_due_for_follow_up' do
    let(:user) { create :user }

    subject { user.relationships_with_statuses_due_for_follow_up }

    before do
      create :client_status, name: 'Active', followup_date: 60, department: user.department
      client = create :client
      @rr1 = ReportingRelationship.create(
        user: user,
        client: client,
        client_status: ClientStatus.find_by(name: 'Active'),
        last_contacted_at: 56.days.ago
      )
    end

    it 'returns clients requiring follow-up' do
      expect(subject).to eq('Active' => [@rr1.id])
    end

    context 'there are inactive clients' do
      before do
        create :client_status, name: 'Active', followup_date: 60, department: user.department
        client = create :client
        @rr2 = ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Active'),
          last_contacted_at: 56.days.ago,
          active: false
        )
      end

      it 'returns only the clients requiring follow-up' do
        expect(subject).to eq('Active' => [@rr1.id])
      end
    end

    context 'multiple statuses' do
      before do
        create :client_status, name: 'Exited', followup_date: 90, department: user.department
        client = create :client
        @rr2 = ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Exited'),
          last_contacted_at: 86.days.ago
        )
      end

      it 'returns the full set of clients requiring follow-up' do
        expect(subject).to eq('Active' => [@rr1.id], 'Exited' => [@rr2.id])
      end

      context 'multiple clients within a status' do
        before do
          create :client_status, name: 'Exited', followup_date: 90, department: user.department
          client = create :client
          @rr3 = ReportingRelationship.create(
            user: user,
            client: client,
            client_status: ClientStatus.find_by(name: 'Exited'),
            last_contacted_at: 86.days.ago
          )
        end

        it 'returns the full set of clients requiring follow-up' do
          expect(subject['Active']).to eq([@rr1.id])
          expect(subject['Exited']).to match_array([@rr2.id, @rr3.id])
        end
      end
    end

    context 'there are clients that do not require follow-up' do
      before do
        create :client_status, name: 'Exited', followup_date: 90, department: user.department
        client = create :client
        @rr2 = ReportingRelationship.create(
          user: user,
          client: client,
          client_status: ClientStatus.find_by(name: 'Exited'),
          last_contacted_at: 20.days.ago
        )
      end

      it 'does not return clients not requiring follow-up' do
        expect(subject).to eq('Active' => [@rr1.id])
      end
    end

    context 'there are clients with null follow-up dates' do
      before do
        @status = create :client_status, name: 'Exited', department: user.department
        client = create :client
        @rr2 = ReportingRelationship.create(
          user: user,
          client: client,
          client_status: @status,
          last_contacted_at: 0
        )
      end

      it 'does not return clients with statuses with nil followup_date' do
        subject
        expect(subject).to eq('Active' => [@rr1.id])
      end
    end
  end
end
