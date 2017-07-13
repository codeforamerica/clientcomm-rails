require 'rails_helper'

describe MessagesController do
  let(:user) {create(:user)}

  before do
    sign_in user
  end

  describe '#create' do
    let(:sms_service) {double(:sms_service)}
    let(:message_text) {'Message text'}
    let(:client) { create(:client, user: user) }
    let(:new_message) {build(:message, client: client)}
    before do
      allow(sms_service).to receive(:send_message).and_return(new_message)
      allow(SMSService).to receive(:instance).and_return(sms_service)

      post :create, format: :js, params: {
          message: { body: message_text },
          client_id: client.id
      }
    end

    it 'returns a 204' do
      expect(response.code).to eq '204'
    end

    it 'call the SMSService with the params', :skip => "skipping until missing host error on url helper is resolved" do
      expect(sms_service)
          .to have_received(:send_message)
                  .with(user: user, client: client, body: message_text, callback_url: incoming_sms_status_url)
    end

    it 'tracks analytics' do
      expect_analytics_events(
          {
              'message_send' => {
                  'client_id' => client.id,
                  'message_id' => new_message.id,
                  'message_length' => new_message.body.length
              }
          }
      )
    end
  end
end
