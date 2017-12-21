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

    subject { get admin_client_relationships_path }

    it 'displays a list of clients' do
      subject

      expected_department_string = department1.name.to_s
      expected_user_string = user1.full_name.to_s

      response_html = Nokogiri.parse(response.body)
      client_row = response_html.css("#reporting_relationship_#{rr1.id}").first

      expect(client_row.content).to include(client.full_name)
      expect(client_row.content).to include(expected_department_string)
      expect(client_row.content).to include(expected_user_string)
    end
  end

  describe 'GET#show' do
    let(:client) { create :client, first_name: 'Joey', last_name: 'Morrison' }
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

  describe '#deactivate' do
    let(:client) { create :client }
    let!(:rr1) do
      ReportingRelationship.create(
        client: client,
        user: user1,
        active: true
      )
    end

    it 'deactivates a reporting relationship' do
      post deactivate_admin_client_path(client), params: {
        reporting_relationship_id: rr1.id
      }

      expect(rr1.reload.active).to eq(false)
      expect(flash[:success]).to include "#{client.full_name} has been deactivated for #{user1.full_name} in #{department1.name}."
      expect(response).to redirect_to(admin_client_path(client))
    end
  end

  describe '#reactivate' do
    let(:client) { create :client }
    let!(:rr1) do
      ReportingRelationship.create(
        client: client,
        user: user1,
        active: false
      )
    end

    it 'reactivates a reporting relationship' do
      post reactivate_admin_client_path(client), params: {
        reporting_relationship_id: rr1.id
      }

      expect(rr1.reload.active).to eq(true)
      expect(flash[:success]).to include "#{client.full_name} has been reactivated for #{user1.full_name} in #{department1.name}."
      expect(response).to redirect_to(admin_client_path(client))
    end
  end

  describe 'PUT#update' do
    let(:client) { create :client }
    let(:first_name) { 'Joanne' }
    let(:last_name) { 'Smith' }
    let(:phone_number) { 'Some phone number' }
    let(:params) do
      {
        client: {
          first_name: first_name,
          last_name: last_name,
          phone_number: phone_number
        }
      }
    end

    it 'updates the user properties' do
      put admin_client_path(client), params: params

      client_reloaded = client.reload
      expect(client_reloaded.first_name).to eq first_name
      expect(client_reloaded.last_name).to eq last_name
      expect(client_reloaded.phone_number).to eq phone_number
    end
  end
end
