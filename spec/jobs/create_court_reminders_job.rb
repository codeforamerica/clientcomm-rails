require 'rails_helper'

RSpec.describe CreateCourtRemindersJob, active_job: true, type: :job do
  describe '#perform' do
    let(:csv) { CourtDateCSV.create!(file: File.new('./spec/fixtures/court_dates.csv')) }
    it 'running the job sends the expected data to ActionCable' do
      described_class.perform_now(csv)
      expect(CourtReminderImporter).to receive(:generate_reminders).with
    end
  end
end
