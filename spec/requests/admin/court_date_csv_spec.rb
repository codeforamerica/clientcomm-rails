require 'rails_helper'

describe 'upload court date csv', type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  let(:admin_user) { create :admin_user }

  before do
    login_as admin_user, scope: :admin_user
  end

  describe 'GET#new' do
    before { get new_admin_court_date_csv_path }

    it 'renders the correct form' do
      expect(response.body).to include 'Upload CSV'
    end
  end

  describe 'POST#create' do
    let(:department) { create :department }
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
      }.to have_enqueued_job(CreateCourtRemindersJob).with(CourtDateCSV, admin_user)
      expect(CourtDateCSV.all.first.admin_user).to eq(admin_user)
      expect_analytics_events(
        'court_reminder_upload' => {
          'admin_id' => admin_user.id
        }
      )
    end
    it 'redirects to the listing page' do
      subject
      expect(response).to redirect_to(admin_court_date_csvs_path)
    end
  end

  describe 'GET#show' do
    let(:filename) { 'court_dates.csv' }
    let(:court_date_csv) { CourtDateCSV.create!(file: File.new("./spec/fixtures/#{filename}"), admin_user: admin_user) }
    before { get admin_court_date_csv_path court_date_csv }

    it 'renders the show page with a download link' do
      page = Nokogiri.parse(response.body)

      expect(page.css('div.panel h3').text).to eq 'Court Reminder CSV Details'
      expect(page.css('tr.row-file_file_name a').attr('href').text).to eq download_admin_court_date_csv_path(court_date_csv)
    end
  end
end
