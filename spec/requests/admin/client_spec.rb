require 'rails_helper'

describe 'Clients', type: :request, active_job: true do
  let(:department1) { create :department, name: 'AAA' }
  let(:department2) { create :department, name: 'BBB' }
  let(:department3) { create :department, name: 'CCC' }
  let(:user1) { create :user, department: department1 }
  let(:user2) { create :user, department: department1 }
  let(:user3) { create :user, department: department2 }
  let(:user4) { create :user, department: department3 }

  before do
    @admin_user = create :admin_user
    login_as @admin_user, scope: :admin_user
  end

  describe 'GET#index' do
    let(:client) { create :client }
    let(:created_at) { 2.days.ago }
    let(:last_contacted_at) { 1.day.ago }
    let(:notes) { 'beep beep i am a note blah' }
    let(:has_unread_messages) { true }
    let(:has_message_error) { true }
    let!(:rr1) do
      ReportingRelationship.create(
        client: client,
        user: user1,
        created_at: created_at,
        last_contacted_at: last_contacted_at,
        notes: notes,
        has_unread_messages: has_unread_messages,
        has_message_error: has_message_error
      )
    end
    let!(:rr2) do
      ReportingRelationship.create(
        client: client,
        user: user3,
        created_at: created_at,
        last_contacted_at: last_contacted_at,
        notes: notes,
        has_unread_messages: has_unread_messages,
        has_message_error: has_message_error
      )
    end

    subject { get admin_clients_path }

    it 'displays a list of clients' do
      subject

      expected_department_string = "#{department1.name}, #{department2.name}"
      expected_user_string = "#{user1.full_name}, #{user3.full_name}"

      response_html = Nokogiri.parse(response.body)
      client_row = response_html.css("#client_#{client.id}").first

      expect(client_row.content).to include(client.full_name)
      expect(client_row.content).to include(expected_department_string)
      expect(client_row.content).to include(expected_user_string)
    end

    context 'a relationship is inactive' do
      let!(:rr2) do
        ReportingRelationship.create(
          client: client,
          user: user3,
          active: false
        )
      end

      it 'does not display users with inactive relationships' do
        subject

        response_html = Nokogiri.parse(response.body)
        client_row = response_html.css("#client_#{client.id}").first

        expect(client_row.content).to_not include(department2.name)
        expect(client_row.content).to_not include(user3.full_name)
      end
    end

    context 'only the correct departments are shown' do
      let(:client2) { create :client }
      let!(:rr2) do
        ReportingRelationship.create(
          client: client2,
          user: user3
        )
      end

      it 'does not display users with inactive relationships' do
        subject

        response_html = Nokogiri.parse(response.body)
        client_row = response_html.css("#client_#{client2.id}").first

        expect(client_row.content).to_not include(department1.name)
        expect(client_row.content).to_not include(user1.full_name)
      end
    end
  end

  describe 'GET#show' do
    let(:client) { create :client }
    let(:created_at) { 2.days.ago }
    let(:last_contacted_at) { 1.day.ago }
    let(:notes) { 'beep beep i am a note blah' }
    let(:has_unread_messages) { true }
    let(:has_message_error) { true }
    let!(:rr1) do
      ReportingRelationship.create(
        client: client,
        user: user1,
        created_at: created_at,
        last_contacted_at: last_contacted_at,
        notes: notes,
        has_unread_messages: has_unread_messages,
        has_message_error: has_message_error
      )
    end

    subject { get admin_client_path(client) }

    it 'displays a panel with the correct info' do
      subject
      expect(response.body).to include(client.first_name)
      expect(response.body).to include(client.last_name)
      expect(response.body).to include(client.phone_number)

      expect(response.body).to include("#{user1.department.name}: #{user1.full_name}")

      response_html = Nokogiri.parse(response.body)
      expect(response_html.css("#attributes_table_reporting_relationship_#{rr1.id}")).to be_present
      response_html.css("#attributes_table_reporting_relationship_#{rr1.id}").each do |table|
        expect(table.content).to include(created_at.strftime('%B %d, %Y %l:%M %Z'))
        expect(table.content).to include(notes)
        expect(table.content).to include(last_contacted_at.strftime('%B %d, %Y %l:%M %Z'))
        expect(table.css('.row-has_unread_messages')).to be_present
        expect(table.css('.row-has_message_error')).to be_present

        table.css('.row-has_unread_messages').each do |row|
          expect(row.content).to include('Yes')
        end

        table.css('.row-has_message_error').each do |row|
          expect(row.content).to include('Yes')
        end
      end
    end

    context 'a relationship is inactive' do
      let!(:rr2) do
        ReportingRelationship.create(
          client: client,
          user: user3,
          active: false,
          created_at: created_at,
          last_contacted_at: last_contacted_at,
          notes: notes,
          has_unread_messages: has_unread_messages,
          has_message_error: has_message_error
        )
      end

      it 'displays the inactive relationship' do
        subject
        response_html = Nokogiri.parse(response.body)

        expect(response_html.css("#attributes_table_reporting_relationship_#{rr1.id}")).to be_present

        expect(response_html.css("#attributes_table_reporting_relationship_#{rr2.id}")).to be_present
        response_html.css("#attributes_table_reporting_relationship_#{rr2.id}").each do |table|
          table.css('.row-active').each do |row|
            expect(row.content).to include('No')
          end
        end
      end

      context 'there is an active relationship in the same department' do
        let!(:rr2) do
          ReportingRelationship.create(
            client: client,
            user: user2,
            active: false,
            created_at: created_at,
            last_contacted_at: last_contacted_at,
            notes: notes,
            has_unread_messages: has_unread_messages,
            has_message_error: has_message_error
          )
        end

        it 'only displays the active relationships' do
          subject
          response_html = Nokogiri.parse(response.body)

          expect(response_html.css("#attributes_table_reporting_relationship_#{rr1.id}")).to be_present

          expect(response_html.css("#attributes_table_reporting_relationship_#{rr2.id}")).to_not be_present
        end
      end
    end
  end

  describe 'PUT#update' do
    before do
      create_list :message, 5, client: client, user: user1, send_at: Time.now + 1.day
    end

    context 'transferring a client' do
      let(:client) { create :client, users: [user1, user4] }
      let(:params) do
        { client: { user_ids: [user2.id] } }
      end

      it 'transfers scheduled messages' do
        scheduled_messages = user1.messages.scheduled
        perform_enqueued_jobs do
          put admin_client_path(client), params: {
            client: {
              user_ids: [user2.id, user3.id]
            }
          }
        end
        active_users = client.users
                             .joins(:reporting_relationships)
                             .where(reporting_relationships: { active: true })

        expect(active_users).to include(user2, user3)
        expect(active_users).to_not include(user1, user4)
        expect(user2.messages.scheduled).to include(*scheduled_messages.reload)
        expect(ReportingRelationship.find_by(user: user4, client: client)).to_not be_active
        expect(ReportingRelationship.find_by(user: user1, client: client)).to_not be_active

        emails = ActionMailer::Base.deliveries
        to_addrs = emails.map(&:to)
        expect(to_addrs).to contain_exactly([user2.email], [user3.email])
      end

      it 'disassociates a user if no user is selected in any department' do
        perform_enqueued_jobs do
          put admin_client_path(client), params: {
            client: {
              user_ids: []
            }
          }
        end

        active_users = client.users
                             .joins(:reporting_relationships)
                             .where(reporting_relationships: { active: true })

        expect(active_users.length).to eq(0)
      end

      it 'tracks the transfer action' do
        perform_enqueued_jobs do
          put admin_client_path(client), params: params
        end

        expect_analytics_events({
                                  'client_transfer' => {
                                    'admin_id' => @admin_user.id,
                                    'clients_transferred_count' => 1
                                  }
                                })
      end

      context 'the user does not change' do
        let(:params) { { client: { notes: 'test', user_ids: [user1.id, user4.id] } } }

        it 'does not send unnecessary notifications' do
          perform_enqueued_jobs do
            put admin_client_path(client), params: params
          end

          active_users = client.users
                               .joins(:reporting_relationships)
                               .where(reporting_relationships: { active: true })

          expect(client.reload.notes).to eq 'test'
          expect(ActionMailer::Base.deliveries).to be_empty
          expect(active_users).to include(user1, user4)
        end
      end
    end
  end
end
