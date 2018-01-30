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
      context 'redirect' do
        before do
          subject
        end

        it { should redirect_to(admin_client_relationships_path) }
      end

      context 'clients do not exist' do
        it 'creates clients corresponding to the inputted csv' do
          subject

          expect(user.clients.count).to eq 2

          client1 = user.clients.find_by(phone_number: '4155553329')
          client2 = user.clients.find_by(phone_number: '2125556230')

          expect(client1.first_name).to eq 'Person'
          expect(client1.last_name).to eq 'McPersonFace'

          expect(client2.first_name).to eq 'Cat'
          expect(client2.last_name).to eq 'McCatFace'
        end
      end

      context 'client has an inactive relationship with another user' do
        let(:user2) { create :user, department: department }
        let!(:client) { create :client, user: user2, phone_number: '2125556230' }

        before do
          rr = client.reporting_relationships.find_by(user: user2)
          rr.update!(active: false)
        end

        it 'creates a new relationship' do
          subject

          client1 = user.clients.find_by(phone_number: '2125556230')
          rr1 = client1.reporting_relationships.find_by(user: user)
          expect(rr1.active).to eq true

          rr2 = client1.reporting_relationships.find_by(user: user2)
          expect(rr2.active).to eq false
        end
      end

      context 'client has inactive relationship with requested user' do
        let!(:client) { create :client, user: user, phone_number: '2125556230' }

        before do
          rr = client.reporting_relationships.find_by(user: user)
          rr.update!(active: false)
        end

        it 'makes the inactive relationship active' do
          subject

          client1 = user.clients.find_by(phone_number: '2125556230')

          expect(client1.first_name).to eq client.first_name
          expect(client1.last_name).to eq client.last_name

          rr1 = client1.reporting_relationships.find_by(user: user)
          expect(rr1.active).to eq true
        end
      end

      context 'client has active relationship with a user in another department' do
        let(:department2) { create :department }
        let(:user2) { create :user, department: department2 }
        let!(:client) { create :client, user: user2, phone_number: '2125556230' }

        it 'creates a new relationship' do
          client1 = user2.clients.find_by(phone_number: '2125556230')
          rr1 = client1.reporting_relationships.find_by(user: user)
          expect(rr1).to be_nil
          rr2 = client1.reporting_relationships.find_by(user: user2)
          expect(rr2.active).to eq true

          subject

          rr1 = client1.reporting_relationships.find_by(user: user)
          expect(rr1.active).to eq true
          rr2 = client1.reporting_relationships.find_by(user: user2)
          expect(rr2.active).to eq true
        end
      end
    end

    context 'invalid clients' do
      context 'client has active relationship with a different user in the same department' do
        let(:user3) { create :user, department: department }
        let!(:client) { create :client, user: user3, phone_number: '2125556230' }

        it 'shows a validation error' do
          subject
          expect(response.body).to include 'Invalid Clients'
        end

        it 'does not create clients corresponding to the inputted csv' do
          subject
          expect(user.clients.count).to eq 0
        end
      end

      context 'client has active relationship with requested user' do
        let!(:client) { create :client, user: user, phone_number: '2125556230' }

        it 'creates other clients corresponding to the inputted csv' do
          subject
          expect(user.clients.count).to eq 2

          client1 = user.clients.find_by(phone_number: '4155553329')
          client2 = user.clients.find_by(phone_number: '2125556230')

          expect(client1.first_name).to eq 'Person'
          expect(client1.last_name).to eq 'McPersonFace'

          expect(client2.first_name).to eq client.first_name
          expect(client2.last_name).to eq client.last_name
        end
      end
    end
  end
end
