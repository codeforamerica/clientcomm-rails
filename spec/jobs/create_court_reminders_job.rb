require 'rails_helper'

RSpec.describe CreateCourtRemindersJob, active_job: true, type: :job do
  describe '#perform' do
    let(:court_dates_path) { Rails.root.join('spec', 'fixtures', 'court_dates.csv') }
    let(:court_locs_path) { Rails.root.join('app', 'assets', 'config', 'court_locations.csv') }
    let(:csv) { CourtDateCSV.create!(file: File.new('./spec/fixtures/court_dates.csv')) }
    let(:court_dates) { CSV.parse(File.read(court_dates_path), headers: true) }
    let(:court_locs) { CSV.parse(File.read(court_locs_path), headers: true) }
    let(:court_locs_hash) { CourtRemindersImporter.generate_locations_hash(court_locs) }

    it 'running the job sends calls CourtRemindersImporter' do
      allow(CourtRemindersImporter).to receive(:generate_reminders)
      described_class.perform_now(csv)
      expect(CourtRemindersImporter).to have_received(:generate_reminders).with(court_dates, court_locs_hash)
    end
  end
end
