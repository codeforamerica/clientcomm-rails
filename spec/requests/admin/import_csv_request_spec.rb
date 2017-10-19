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
    let!(:user) { create :user, email: 'test@example.com' }

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

        client_1 = user.clients.find_by_phone_number('4155553329')
        client_2 = user.clients.find_by_phone_number('2125556230')

        expect(client_1.first_name).to eq 'Person'
        expect(client_1.last_name).to eq 'McPersonFace'

        expect(client_2.first_name).to eq 'Cat'
        expect(client_2.last_name).to eq 'McCatFace'
      end
    end

    context 'invalid clients' do
      before do
        create :client, phone_number: '2125556230'
        subject
      end

      it 'shows a validation error' do
        expect(response.body).to include 'Invalid Clients'
      end

      it 'creates clients corresponding to the inputted csv' do
        expect(user.clients.count).to eq 0
      end
    end
  end
end
