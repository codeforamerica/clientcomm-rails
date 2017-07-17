require 'rails_helper'

describe ScheduledMessageJob, active_job: true, type: :job do
  let(:message){ create :message }
  subject(:scheduled_job){ ScheduledMessageJob.perform_later(message: message, callback_url: 'whocares.com') }

  it 'calls SMSService when performed' do
    expect(SMSService.instance).to receive(:send_message).with(message: message, callback_url: 'whocares.com')
    perform_enqueued_jobs { scheduled_job }
  end
end
