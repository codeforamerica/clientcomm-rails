require 'rails_helper'

describe 'Merge Reporting Relationship Requests', type: :request do
  let(:department) { create :department }
  let!(:user) { create :user, department: department }

  before do
    sign_in user
  end

  describe 'POST#create' do
    let(:phone_number) { '+14155555550' }
    let(:phone_number_display) { '(415) 555-5550' }
    let(:phone_number_selected) { '+14155555552' }
    let(:phone_number_selected_display) { '(415) 555-5552' }
    let(:first_name) { 'Feaven X.' }
    let(:first_name_selected) { 'Feaven' }
    let(:last_name) { 'Girma' }
    let(:last_name_selected) { 'Girma' }
    let(:client) { create :client, user: user, phone_number: phone_number, first_name: first_name, last_name: last_name }
    let(:selected_client) { create :client, user: user, phone_number: phone_number_selected, first_name: first_name_selected, last_name: last_name_selected }
    let(:full_name_client) { client }
    let(:phone_number_client) { selected_client }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let(:rr_selected) { ReportingRelationship.find_by(user: user, client: selected_client) }

    subject do
      post merge_reporting_relationships_path, params: {
        merge_reporting_relationship: {
          client_id: client.id,
          selected_client_id: selected_client.id,
          merge_clients: {
            full_name: full_name_client.id,
            phone_number: phone_number_client.id
          }
        }
      }
    end

    before do
      create_list :text_message, 5, reporting_relationship: rr
      create_list :text_message, 5, reporting_relationship: rr_selected
    end

    it 'merges the clients' do
      subject

      rr_from = rr
      rr_to = rr_selected

      expect(rr_from.reload.active).to eq false
      expect(rr_from.messages.count).to eq 0
      expect(rr_to.reload.active).to eq true
      expect(rr_to.messages.where(type: TextMessage.to_s).count).to eq 10

      conversation_ends_marker = rr_to.messages.where(type: ConversationEndsMarker.to_s).first
      expect(conversation_ends_marker).to_not be_nil
      conversation_ends_marker_body = I18n.t(
        'messages.conversation_ends',
        full_name: "#{first_name} #{last_name}",
        phone_number: phone_number_display
      )
      expect(conversation_ends_marker.body).to eq(conversation_ends_marker_body)

      merged_with_marker = rr_to.messages.where(type: MergedWithMarker.to_s).first
      expect(merged_with_marker).to_not be_nil
      merged_with_marker_body = I18n.t(
        'messages.merged_with',
        from_full_name: "#{first_name} #{last_name}",
        from_phone_number: phone_number_display,
        to_full_name: "#{first_name_selected} #{last_name_selected}",
        to_phone_number: phone_number_selected_display
      )
      expect(merged_with_marker.body).to eq(merged_with_marker_body)
    end
  end
end
