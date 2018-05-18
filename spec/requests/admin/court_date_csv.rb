require 'rails_helper'

describe 'upload court date csv', type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  before do
    admin_user = create :admin_user
    login_as admin_user, scope: :admin_user
  end

  describe 'GET#index' do
    before { get admin_court_date_csvs_path }

    it { should redirect_to(new_admin_court_date_csv_path) }
  end

  describe 'GET#new' do
    before { get new_admin_court_date_csv_path }

    it 'renders the correct form' do
      expect(response.body).to include 'Upload CSV'
    end
  end

  describe 'POST#create' do
    let(:department) { create :department }
    let!(:user) { create :user, department: department, email: 'test@example.com' }

    subject do
      file = fixture_file_upload('court_dates.csv', 'text/csv')
      post admin_court_date_csvs_path, params: {
        court_date_csv: {
          file: file
        }
      }
    end

    it 'calls delayed job to create reminders' do
      expect {
        subject
      }.to have_enqueued_job(CreateCourtRemindersJob)
    end
  end
end


