require 'rails_helper'

describe 'Clients requests', type: :request do
  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      get clients_path
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'authenticated' do
    let(:user) { create :user }

    before do
      sign_in user
    end

    describe 'POST#create' do
      before do
        create_client client
      end

      context 'receives valid client parameters' do
        let(:client) { build(:client) }

        it 'creates a client' do
          expect(response.code).to eq '302'
          expect(response).to redirect_to clients_path
          expect(Client.count).to eq 1
        end

        it 'tracks the creation of a new client' do
          created_client = Client.find_by(phone_number: client.phone_number)

          expect_analytics_events(
              {
                  'client_create_success' => {
                      'client_id' => created_client.id
                  }
              }
          )
        end
      end

      context 'receives invalid client parameters' do
        let(:client) { build(:client, last_name: nil) }

        it 'renders new with validation errors' do
          expect(response.code).to eq '200'
          expect(Client.count).to eq 0
          expect(client.valid?).to be_falsey
          expect([:last_name]).to eq client.errors.keys
        end
      end
    end

    describe 'get#index' do
      before do
        create_list :client, 5, user: user
      end

      subject { get clients_path }

      it 'returns a list of clients' do
        subject

        user.clients.each do |client|
          expect(Nokogiri.parse(response.body).to_s).to include("#{client.first_name} #{client.last_name}")
        end
      end

      context 'there are archived clients' do
        let(:archived_client) { user.clients.first }

        before do
          archived_client.active = false
          archived_client.save
        end

        it 'does not return archived clients' do
          subject

          expect(response.body).to_not include("#{archived_client.first_name} #{archived_client.last_name}")
        end
      end
    end

    describe 'post#archive' do
      let(:client) { create_client build(:client) }
      subject { post client_archive_path(client), params: { client: { active: false } } }

      it 'shows a confirmation page' do
        subject

        expect(Nokogiri.parse(response.body).to_s).to include("#{client.first_name} #{client.last_name} will no longer appear in ClientComm")

        expect(client.reload.active).to eq(false)
      end
    end
  end
end
