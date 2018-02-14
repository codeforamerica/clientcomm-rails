require 'rails_helper'
require 'rake'

describe 'reports rake tasks' do
  describe 'reports:generate_and_send_reports', type: :request do
    let(:department) { create :department }
    let(:report_count) { 5 }
    let!(:report_list) { create_list :report, report_count, department: department }
    let(:report_date) { Time.now.change(usec: 0, hour: 5) }
    let(:day_of_week) { report_date }

    before do
      Rake.application.rake_require 'tasks/reports'
      Rake::Task.define_task(:environment)
      @weekday = ENV['REPORT_DAY']
      ENV['REPORT_DAY'] = day_of_week.wday.to_s
    end

    after do
      ENV['REPORT_DAY'] = @weekday
    end

    it 'calls NotificationMailer.report_usage part' do
      metrics = department.message_metrics(report_date)
      report_list.each do |report|
        expect(NotificationMailer).to receive(:report_usage)
          .with(report.email, metrics, report_date.to_s)
          .and_return(double('NotificationMailer', deliver_later: true))
      end
      travel_to report_date do
        Rake::Task['reports:generate_and_send_reports'].reenable
        Rake.application.invoke_task 'reports:generate_and_send_reports'
      end
    end
    context 'on incorrect day' do
      let(:day_of_week) { report_date - 1.day }
      it 'does not call NotificationMailer.report_usage part two' do
        metrics = department.message_metrics(report_date)
        expect(NotificationMailer).to_not receive(:report_usage)
        travel_to report_date do
          Rake::Task['reports:generate_and_send_reports'].reenable
          Rake.application.invoke_task 'reports:generate_and_send_reports'
        end
      end
    end
  end
end
