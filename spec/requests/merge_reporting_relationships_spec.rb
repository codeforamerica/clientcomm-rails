require 'rails_helper'

describe 'Merge Reporting Relationship Requests', type: :request do
  let(:department) { create :department }
  let!(:user) { create :user, department: department }

  before do
    sign_in user
  end

  describe 'POST#create' do
    let(:other_user) { user }
    let(:phone_number) { '+14155555550' }
    let(:phone_number_selected) { '+14155555552' }
    let(:first_name) { 'Feaven X.' }
    let(:first_name_selected) { 'Feaven' }
    let(:last_name) { 'Girma' }
    let(:last_name_selected) { 'Girma' }
    let(:client) { create :client, user: user, phone_number: phone_number, first_name: first_name, last_name: last_name }
    let(:client_selected) { create :client, user: user, phone_number: phone_number_selected, first_name: first_name_selected, last_name: last_name_selected }
    let(:full_name_client) { client }
    let(:phone_number_client) { client_selected }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let(:rr_selected) { ReportingRelationship.find_by(user: other_user, client: client_selected) }

    subject do
      post merge_reporting_relationships_path, params: {
        merge_reporting_relationship: {
          client_id: client.id,
          selected_client_id: client_selected.id,
          merge_clients: {
            full_name: full_name_client.id,
            phone_number: phone_number_client.id
          }
        }
      }
    end

    before do
      travel_to(4.days.ago) { create_list :text_message, 2, reporting_relationship: rr, read: true }
      travel_to(3.days.ago) { create_list :text_message, 3, reporting_relationship: rr, read: true }
      rr.update!(last_contacted_at: rr.messages.order(:send_at).last.send_at)
      travel_to(2.days.ago) { create_list :text_message, 3, reporting_relationship: rr_selected, read: true }
      travel_to(1.day.ago) { create_list :text_message, 2, reporting_relationship: rr_selected, read: true }
      rr_selected.update!(last_contacted_at: rr_selected.messages.order(:send_at).last.send_at)
    end

    it 'merges the clients' do
      subject

      rr_from = rr
      rr_to = rr_selected

      expect(rr_from.reload.active).to eq false
      expect(rr_from.messages.count).to eq 0
      expect(rr_to.reload.active).to eq true
      expect(rr_to.messages.where(type: TextMessage.to_s).count).to eq 10

      expect_most_recent_analytics_event(
        'client_merge_success' => {
          'client_id' => rr_from.client.id,
          'selected_client_id' => rr_to.client.id,
          'preserved_client_id' => rr_to.client.id
        }
      )

      expect(response).to redirect_to reporting_relationship_path rr_to
    end

    context 'the phone number of the current client is selected' do
      let(:phone_number_client) { client }

      it 'merges the clients' do
        subject

        rr_from = rr_selected
        rr_to = rr

        expect(rr_from.reload.active).to eq false
        expect(rr_from.messages.count).to eq 0
        expect(rr_to.reload.active).to eq true
        expect(rr_to.messages.where(type: TextMessage.to_s).count).to eq 10

        expect_most_recent_analytics_event(
          'client_merge_success' => {
            'client_id' => rr_to.client.id,
            'selected_client_id' => rr_from.client.id,
            'preserved_client_id' => rr_to.client.id
          }
        )

        expect(response).to redirect_to reporting_relationship_path rr_to
      end
    end

    context 'relationships belonging to different users are submitted' do
      let(:other_user) { create :user, department: department }
      let!(:client_selected) { create :client, user: other_user, phone_number: phone_number_selected, first_name: first_name_selected, last_name: last_name_selected }

      it 're-renders the page with an error message' do
        subject

        expect(response.code).to eq '302'
        expect(response).to redirect_to edit_client_path client
        expect(flash[:alert]).to eq I18n.t('flash.errors.merge.invalid')
      end
    end

    context 'a RecordInvalid exception is raised during the merge' do
      before do
        allow_any_instance_of(ReportingRelationship).to receive(:update!).with(active: false).and_raise ActiveRecord::RecordInvalid
      end

      it 're-renders the page with an error message' do
        subject

        expect(response.code).to eq '302'
        expect(response).to redirect_to edit_client_path client
        expect(flash[:alert]).to eq I18n.t('flash.errors.merge.invalid')
      end
    end
  end
end
