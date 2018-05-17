require 'rails_helper'

RSpec.describe CreateCourtRemindersJob, active_job: true, type: :job do
  describe '#perform' do
    let(:court_dates_path) { Rails.root.join('spec', 'fixtures', 'court_dates.csv') }
    let(:court_locs_path) { Rails.root.join('app', 'assets', 'config', 'court_locations.csv') }
    let(:csv) { CourtDateCSV.create!(file: File.new('./spec/fixtures/court_dates.csv')) }
    let(:court_dates) { CSV.parse(File.read(court_dates_path), headers: true) }
    let(:court_locs) { CSV.parse(File.read(court_locs_path), headers: true) }
    let(:court_locs_hash) { CourtRemindersImporter.generate_locations_hash(court_locs) }
    let(:user) { create :admin_user }

    subject do
      described_class.perform_now(csv, user)
    end

    it 'running the job sends calls CourtRemindersImporter' do
      expect(CourtRemindersImporter).to receive(:generate_reminders).with(court_dates, court_locs_hash)
      subject
    end

    it 'sends email on success' do
      perform_enqueued_jobs { subject }
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to include 'Your recent ClientComm upload - success!'
      expect(mail.html_part.to_s).to include '0 court reminders were successfully scheduled'
    end

    context 'import fails' do
      let(:csv) { CourtDateCSV.create!(file: File.new('./spec/fixtures/bad_court_dates.csv')) }
      let!(:rr) { create :reporting_relationship, notes: '111', active: true }
      it 'sends failure email' do
        perform_enqueued_jobs { subject }
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq([user.email])
        expect(mail.subject).to include 'Error with your recent ClientComm upload'
        expect(mail.html_part.to_s).to include 'not able to process your recent CSV'
      end
    end
  end
end