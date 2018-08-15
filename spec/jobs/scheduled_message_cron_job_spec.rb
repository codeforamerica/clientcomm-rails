require 'rails_helper'

describe ScheduledMessageCronJob, active_job: true, type: :job do
  let!(:sent_message) { create :text_message, sent: true, send_at: Time.zone.now }
  let!(:future_message) { create :text_message, sent: false, send_at: Time.zone.now + 20.minutes }
  let!(:send_message) { create :text_message, sent: false, send_at: Time.zone.now }
  subject do
    ScheduledMessageCronJob.perform_now
  end
  it 'schedules jobs' do
    subject
    send_message.reload
    expect(ScheduledMessageJob).to_not have_been_enqueued.with(message: future_message.reload)
    expect(ScheduledMessageJob).to_not have_been_enqueued.with(message: sent_message.reload)
    expect(ScheduledMessageJob).to have_been_enqueued.with(message: send_message).at(send_message.send_at)
  end
end
