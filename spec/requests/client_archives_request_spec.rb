require 'rails_helper'

describe 'Clients requests', type: :request do
  let(:user) { create :user }

  before do
    sign_in user

    @survey = ENV['TYPEFORM_LINK']
    ENV['TYPEFORM_LINK'] = typeform_link
  end

  after do
    ENV['TYPEFORM_LINK'] = @survey
  end

  describe 'post#archive' do
    let(:typeform_link) { 'whatever' }

    let(:client) { create :client, user: user, created_at: Time.zone.local(2003, 01, 01, 01, 01, 01) }
    subject do
      post client_archive_path(client), params: {
        client: {
          reporting_relationships_attributes: {
            id: client.reporting_relationships.find_by(user: user).id,
            active: false
          }
        }
      }
    end

    it 'shows a confirmation page' do
      travel_to Time.zone.local(2003, 03, 24, 01, 04, 44) do
        subject
      end

      expect(Nokogiri.parse(response.body).to_s).to include("#{client.first_name} #{client.last_name} will no longer appear in ClientComm")

      expect(client.reporting_relationships.find_by(user: user).active).to eq(false)

      expect_analytics_events(
        {
          'client_archive_success' => {
            'client_id' => client.id,
            'client_duration' => 82
          }
        }
      )
    end

    context 'there is no survey link' do
      let(:typeform_link) { '' }

      it 'redirects to the client list with a flash' do
        subject

        expect(flash[:notice]).to include('successfully deleted')
      end
    end
  end
end
