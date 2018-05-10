require 'rails_helper'
require 'rake'

describe 'import rake tasks' do
  describe 'import:slco_court_reminders', active_job: true do
    let(:court_dates_path) { Rails.root.join('spec', 'fixtures', 'court_dates.csv') }
    let(:court_locs_path) { Rails.root.join('spec', 'fixtures', 'court_locs.csv') }

    before do
      load File.expand_path('../../lib/tasks/import.rake', __dir__)
      Rake::Task.define_task(:environment)

      travel_to Time.strptime('5/1/2018 8:30 -0600', '%m/%d/%Y %H:%M %z')
    end

    after do
      travel_back
    end

    let!(:rr1) { create :reporting_relationship, notes: '111' }
    let!(:rr2) { create :reporting_relationship, notes: '202' }
    let!(:rr3) { create :reporting_relationship, notes: '321' }
    let!(:rr4) { create :reporting_relationship, notes: '867' }

    it 'imports messages and clears old messages' do
      perform_enqueued_jobs do
        expect(rr1.messages).to be_empty

        Rake::Task['import:slco_court_reminders'].invoke(court_dates_path, court_locs_path)

        expect(rr1.messages.count).to eq(1)
        expect(rr2.messages.count).to eq(2)
        expect(rr3.messages.count).to eq(1)
        expect(rr4.messages.count).to eq(1)
      end
    end
  end
end
