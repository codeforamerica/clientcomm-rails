require 'rails_helper'
require 'rake'

describe 'import rake tasks' do
  describe 'import:slco_court_reminders', active_job: true do
    before do
      load File.expand_path('../../lib/tasks/import.rake', __dir__)
      Rake::Task.define_task(:environment)
    end

    it 'imports messages and clears old messages' do
      perform_enqueued_jobs do
        Rake::Task['import:slco_court_reminders'].invoke(params?)
      end
    end
  end
end
