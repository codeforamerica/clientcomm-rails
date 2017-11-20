require 'rails_helper'

describe 'import csv', type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  before do
    admin_user = create :admin_user
    login_as admin_user, scope: :admin_user
  end

  describe 'GET#index' do
    before { get admin_import_csvs_path }

    it { should redirect_to(new_admin_import_csv_path) }
  end

  describe 'GET#new' do
    before { get new_admin_import_csv_path }

    it 'renders the correct form' do
      expect(response.body).to include 'Upload CSV'
      expect(response.body).to include 'Cancel'
    end
  end

  describe 'POST#create' do
    let(:department) { create :department }
    let!(:user) { create :user, department: department, email: 'test@example.com' }

    subject do
      file = fixture_file_upload('test.csv', 'text/csv')
      post admin_import_csvs_path, params: {
        import_csv: {
          file: file
        }
      }
    end

    context 'valid clients' do
      before do
        subject
      end

      it { should redirect_to(admin_clients_path) }

      it 'creates clients corresponding to the inputted csv' do
        expect(user.clients.count).to eq 2

        client1 = user.clients.find_by_phone_number('4155553329')
        client2 = user.clients.find_by_phone_number('2125556230')

        expect(client1.first_name).to eq 'Person'
        expect(client1.last_name).to eq 'McPersonFace'

        expect(client2.first_name).to eq 'Cat'
        expect(client2.last_name).to eq 'McCatFace'
      end
    end

    context 'invalid clients' do
      context 'client belongs to a different user in the same department' do
        let(:another_user) { create :user, department: department }
        let!(:client) { create :client, user: another_user, phone_number: '2125556230' }
        it 'shows a validation error' do
          subject
          expect(response.body).to include 'Invalid Clients'
        end

        it 'creates clients corresponding to the inputted csv' do
          subject
          expect(user.clients.count).to eq 0
        end
      end

      context 'client belongs to requested user' do
        let!(:client) { create :client, user: user, phone_number: '2125556230' }

        it 'creates clients corresponding to the inputted csv' do
          subject
          expect(user.clients.count).to eq 2

          client1 = user.clients.find_by_phone_number('4155553329')
          client2 = user.clients.find_by_phone_number('2125556230')

          expect(client1.first_name).to eq 'Person'
          expect(client1.last_name).to eq 'McPersonFace'

          expect(client2.first_name).to eq client.first_name
          expect(client2.last_name).to eq client.last_name
        end
      end
    end
  end
end
