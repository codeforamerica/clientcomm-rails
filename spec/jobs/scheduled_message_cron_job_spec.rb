require 'rails_helper'

describe ScheduledMessageCronJob, active_job: true, type: :job do
  let!(:sent_message) { create :text_message, inbound: false, sent: true, send_at: Time.zone.now }
  let!(:future_message) { create :text_message, inbound: false, sent: false, send_at: Time.zone.now + 20.minutes }
  let!(:inbound_message) { create :text_message, inbound: true, send_at: Time.zone.now }
  let!(:send_message) { create :text_message, inbound: false, sent: false, send_at: Time.zone.now }
  subject do
    ScheduledMessageCronJob.perform_now
  end
  it 'schedules jobs' do
    subject
    send_message.reload
    expect(ScheduledMessageJob).to_not have_been_enqueued.with(message: future_message.reload)
    expect(ScheduledMessageJob).to_not have_been_enqueued.with(message: sent_message.reload)
    expect(ScheduledMessageJob).to_not have_been_enqueued.with(message: inbound_message.reload)
    expect(ScheduledMessageJob).to have_been_enqueued.with(message: send_message).at(send_message.send_at)
  end
  it 'puts cloudwatch metric' do
    now = Time.zone.now.change(usec: 0)
    expect(CLOUD_WATCH).to receive(:put_metric_data).with(
      namespace: ENV['DEPLOYMENT'],
      metric_data: [
        {
          metric_name: 'MessagesScheduled',
          timestamp: now,
          value: 1,
          unit: 'None',
          storage_resolution: 1
        }
      ]
    )
    travel_to now do
      subject
    end
  end
end
