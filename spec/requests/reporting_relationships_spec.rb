require 'rails_helper'

describe 'Reporting Relationship Requests', type: :request, active_job: true do
  let(:department) { create :department }
  let(:user) { create :user, department: department }
  let(:transfer_user) { create :user, department: department }
  let(:transfer_note) { Faker::Lorem.characters(10) }
  let!(:client) { create :client, user: user }
  let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
  let!(:scheduled_messages) { create_list :message, 5, reporting_relationship: rr, send_at: Time.now + 1.day }

  before do
    sign_in user
  end

  describe 'GET#show' do
    let(:department2) { create :department }
    let(:user2) { create :user, department: department2 }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }

    subject do
      get reporting_relationship_path(rr)
    end

    before do
      user2.clients << client
    end

    it 'shows no message dialog if no messages' do
      subject
      message = "You haven’t sent #{client.first_name} any messages yet. Start by introducing yourself."
      expect(response.body).to include(message)
    end

    it 'does not show message dialog if messages exist' do
      create :message, reporting_relationship: rr
      subject
      message = "You haven’t sent #{client.first_name} any messages yet. Start by introducing yourself."
      expect(response.body).to_not include(message)
    end

    it 'shows all past messages for a given relationship' do
      message = create :message, reporting_relationship: rr
      message2 = create :message, reporting_relationship: rr
      message3 = create :message

      subject

      expect(response.body).to include(message.body)
      expect(response.body).to include(message2.body)
      expect(response.body).to_not include(message3.body)
    end

    it 'marks all messages read when index loaded' do
      message = create :message, reporting_relationship: rr, inbound: true
      client.reporting_relationship(user: user).update!(has_unread_messages: true)

      # when we visit the messages path, it should mark the message read
      expect { subject }
        .to change { message.reload.read? }
        .from(false)
        .to(true)
      expect(client.reporting_relationship(user: user).has_unread_messages).to eq(false)
    end

    context 'there are scheduled messages' do
      it 'does not show scheduled messages in the main timeline' do
        message = create :message, reporting_relationship: rr, send_at: Time.now.tomorrow

        subject
        expect(response.body).to_not include(message.body)
      end

      it 'shows messages after their send_at date' do
        travel_to 1.day.ago do
          create :message, reporting_relationship: rr, body: body, send_at: Time.now
        end

        subject
        expect(response.body).to include(body)
      end

      context 'there are no scheduled messages' do
        let!(:scheduled_messages) { nil }

        it 'shows no link when scheduled messages do not exist' do
          subject
          expect(response.body).not_to match(/message[s]? scheduled/)
        end
      end

      it 'shows a link when scheduled messages exist' do
        subject
        expect(response.body).to include("#{scheduled_messages.count} messages scheduled")
      end
    end

    context 'there are attachments' do
      let(:attachment) { build :attachment, media: File.new(media_path) }

      before do
        create :message, reporting_relationship: rr, attachments: [attachment], inbound: true
        subject
      end

      context 'image files' do
        let(:media_path) { 'spec/fixtures/fluffy_cat.jpg' }

        it 'displays files' do
          parsed_response = Nokogiri.parse(response.body)

          expect(parsed_response.css('.message--inbound img').attr('src').text).to include 'fluffy_cat.jpg'
        end
      end

      context 'other file types' do
        let(:media_path) { 'spec/fixtures/cat_contact.vcf' }

        it 'displays files' do
          parsed_response = Nokogiri.parse(response.body)

          expect(parsed_response.css('.message--inbound a').attr('href').text).to include 'cat_contact.vcf'
        end
      end
    end

    context 'for a client the user has an inactive relationship with' do
      it 'should redirect to the clients index view' do
        ReportingRelationship.find_by(user: user, client: client).update(active: false)
        subject

        expect(response).to redirect_to(clients_path)
        expect(flash[:notice]).to include 'The client you tried to view is not in your caseload.'
      end
    end

    context 'for a client the user has no relationship with' do
      subject do
        get reporting_relationship_path(create(:reporting_relationship))
      end

      it 'should redirect to the clients index view' do
        subject

        expect(response).to redirect_to(clients_path)
        expect(flash[:notice]).to include 'The client you tried to view is not in your caseload.'
      end
    end

    context "for a client that doesn't exist" do
      subject do
        get reporting_relationship_path(99999)
      end

      it 'should redirect to the clients index view' do
        subject

        expect(response).to redirect_to(clients_path)
        expect(flash[:notice]).to include 'The client you tried to view is not in your caseload.'
      end
    end
  end

  describe 'POST#create' do
    subject do
      post reporting_relationships_path, params: {
        transfer_note: transfer_note,
        reporting_relationship: {
          user_id: transfer_user.id,
          client_id: client.id
        }
      }
    end

    it 'transfers the client' do
      expect(user.clients.active).to include client
      expect(transfer_user.clients.active).to_not include client

      perform_enqueued_jobs do
        subject
      end

      expect(user.clients.active).to_not include client
      expect(transfer_user.clients.active).to include client

      emails = ActionMailer::Base.deliveries
      to_add = emails.map(&:to)
      body = emails.first.body.encoded
      expect(to_add).to contain_exactly([transfer_user.email])
      expect(body).to include("#{user.full_name} has transferred a client to you")
      expect(body).to include(transfer_note)

      expect_most_recent_analytics_event(
        'client_transfer' => {
          'clients_transferred_count' => 1,
          'transferred_by' => 'user',
          'has_transfer_note' => true
        }
      )
    end

    it 'transfers scheduled messages' do
      expect(user.messages).to include(*scheduled_messages)
      expect(transfer_user.messages).to_not include(*scheduled_messages)
      subject
      expect(user.messages).to_not include(*scheduled_messages.map(&:reload))
      expect(transfer_user.messages.reload).to include(*scheduled_messages)
    end

    it 'creates transfer markers' do
      expect(transfer_user.messages.transfer_markers).to be_empty
      time = Time.now
      travel_to time do
        subject
      end
      expect(transfer_user.messages.transfer_markers.count).to eq(1)
      marker_from = transfer_user.messages.transfer_markers.first
      expect(marker_from.client).to eq(client)

      transfer_message_from_body = I18n.t(
        'messages.transferred_from',
        client_full_name: client.full_name,
        user_full_name: user.full_name
      )
      expect(marker_from.body).to eq(transfer_message_from_body)

      expect(user.messages.transfer_markers.count).to eq(1)
      marker_to = user.messages.transfer_markers.first
      expect(marker_to.client).to eq(client)

      transfer_message_to_body = I18n.t(
        'messages.transferred_to',
        user_full_name: transfer_user.full_name
      )
      expect(marker_to.body).to eq(transfer_message_to_body)
    end

    context 'the user has received messages from the client' do
      let(:rr) { ReportingRelationship.find_by(user: user, client: client) }

      before do
        rr.update!(has_unread_messages: true)
      end

      it 'marks all messages as read' do
        msg = create :message, reporting_relationship: rr, read: false

        subject

        expect(rr.reload.has_unread_messages).to eq(false)
        expect(msg.reload).to be_read
      end
    end

    context 'transfer user has an inactive relationship' do
      before do
        create :reporting_relationship, user: transfer_user, client: client, active: false
      end

      it 'restores the relationship' do
        perform_enqueued_jobs do
          subject
        end

        expect(user.clients.active).to_not include client
        expect(transfer_user.clients.active).to include client
      end
    end

    context 'user_id is blank' do
      subject do
        post reporting_relationships_path, params: {
          reporting_relationship: {
            user_id: nil,
            client_id: client.id
          }
        }
      end

      it 'renders an error' do
        subject
        path = 'activerecord.errors.models.reporting_relationship.attributes.user.blank'
        expect(response.body).to include I18n.t path
      end

      it 'does not deactivate the original rr' do
        subject
        expect(ReportingRelationship.find_by(client_id: client.id, user_id: user.id)).to be_active
      end
    end

    context 'user is the unclaimed user' do
      let!(:unclaimed_messages) { create_list :message, 3, reporting_relationship: rr }

      before do
        department.update!(unclaimed_user: user)
      end

      it 'transfers messages received by the unclaimed user' do
        expect(user.messages).to include(*unclaimed_messages)
        expect(transfer_user.messages).to_not include(*unclaimed_messages)
        subject
        expect(user.messages).to_not include(*unclaimed_messages.map(&:reload))
        expect(transfer_user.messages.reload).to include(*unclaimed_messages)
      end

      it 'does not show the TO transfer marker on the recipient conversation' do
        subject
        expect(user.messages.map(&:body)).to include(I18n.t('messages.transferred_to', user_full_name: transfer_user.full_name))
        expect(transfer_user.messages.map(&:body)).to_not include(I18n.t('messages.transferred_to', user_full_name: transfer_user.full_name))
      end
    end
  end
end
