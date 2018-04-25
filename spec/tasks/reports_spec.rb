require 'rails_helper'
require 'rake'

describe 'reports rake tasks' do
  describe 'reports:generate_and_send_reports', type: :request do
    let(:department) { create :department }
    let(:report_count) { 5 }
    let!(:report_list) { create_list :report, report_count, department: department }
    let(:report_date) { Time.zone.now.change(usec: 0, hour: 5, day: 14, month: 2, year: 2018) }
    let(:day_of_week) { report_date.wday.to_s }

    before do
      Rake.application.rake_require 'tasks/reports'
      Rake::Task.define_task(:environment)
      @weekday = ENV['REPORT_DAY']
      ENV['REPORT_DAY'] = day_of_week
    end

    after do
      ENV['REPORT_DAY'] = @weekday
    end

    it 'calls NotificationMailer.report_usage' do
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
      let(:day_of_week) { (report_date + 1.day).wday.to_s }
      it 'does not call NotificationMailer.report_usage' do
        expect(NotificationMailer).to_not receive(:report_usage)
        travel_to report_date do
          Rake::Task['reports:generate_and_send_reports'].reenable
          Rake.application.invoke_task 'reports:generate_and_send_reports'
        end
      end
    end

    context 'with no default day set' do
      let(:day_of_week) { '' }
      it 'does not call NotificationMailer.report_usage' do
        expect(NotificationMailer).to_not receive(:report_usage)
        travel_to report_date do
          Rake::Task['reports:generate_and_send_reports'].reenable
          Rake.application.invoke_task 'reports:generate_and_send_reports'
        end
      end
    end
  end

  describe 'reports:long_messages', type: :request do
    let(:user_name) { 'Stanislaw Lem' }
    let(:user_email) { 'lem@example.com' }
    let(:user) { create :user, full_name: user_name, email: user_email }
    let(:client1) { create :client, users: [user] }
    let(:client2) { create :client, users: [user] }
    let(:rr1) { ReportingRelationship.find_by(user: user, client: client1) }
    let(:rr2) { ReportingRelationship.find_by(user: user, client: client2) }
    let(:body_length1) { 1605 }
    let(:body_length2) { 1615 }
    let(:long_body1) { (0...body_length1).map { ('a'..'z').to_a[rand(26)] }.join }
    let(:long_body2) { (0...body_length2).map { ('a'..'z').to_a[rand(26)] }.join }
    let(:send_at1) { Time.new(2018, 4, 25, 11, 40) }
    let(:send_at2) { Time.new(2018, 4, 25, 11, 35) }
    let(:message1) { build :message, reporting_relationship: rr1, original_reporting_relationship: rr1, body: long_body1, send_at: send_at1 }
    let(:message2) { build :message, reporting_relationship: rr2, original_reporting_relationship: rr2, body: long_body2, send_at: send_at2 }

    before do
      Rake.application.rake_require 'tasks/reports'
      Rake::Task.define_task(:environment)

      message1.save(validate: false)
      message2.save(validate: false)
    end

    it 'outputs a csv of information about long messages' do
      expected_csv = <<~CSV
        name,email,client,id,length,send_at
        #{user_name},#{user_email},#{client1.first_name} #{client1.last_name},#{client1.id},#{body_length1},#{send_at1}
        #{user_name},#{user_email},#{client2.first_name} #{client2.last_name},#{client2.id},#{body_length2},#{send_at2}
      CSV

      Rake::Task['reports:long_messages'].reenable
      expect { Rake.application.invoke_task 'reports:long_messages' }.to output(expected_csv).to_stdout
    end
  end
end
