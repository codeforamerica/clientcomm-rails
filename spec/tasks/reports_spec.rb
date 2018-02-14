require 'rails_helper'
require 'rake'

describe 'reports rake tasks' do
  describe 'reports:generate_and_send_reports' do
    let(:department) { create :department }
    let(:report_count) { 5 }
    let!(:report_list) { create_list :report, report_count, department: department }
    let(:now) { Time.now.change(usec: 0) }
    before do
      load File.expand_path('../../../lib/tasks/reports.rake', __FILE__)
      Rake::Task.define_task(:environment)
    end
    it 'calls NotificationMailer.report_usage' do
      metrics = department.message_metrics(now)
      report_list.each do |report|
        expect(NotificationMailer).to receive(:report_usage)
          .with(report.email, metrics, now)
          .and_return(double('NotificationMailer', deliver_later: true))
      end
      travel_to now do
        Rake::Task['reports:generate_and_send_reports'].invoke
      end
    end
  end
end
