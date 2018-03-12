require 'rails_helper'

describe MessageRedactionJob, active_job: true, type: :job do
  let(:message) { create :message }

  subject do
    perform_enqueued_jobs { MessageRedactionJob.perform_later(message: message) }
  end

  it 'redacts the message from twilio' do
    expect(SMSService.instance).to receive(:redact_message).with(message: message).and_return(true)

    subject
  end

  context 'twilio returns a 404' do
    let(:error) { Twilio::REST::RestError.new('Not Found', 20404, 404) }

    it 'retries the job' do
      expect(SMSService.instance).to receive(:redact_message).exactly(4).times.with(message: message).and_raise(error)
      expect(SMSService.instance).to receive(:redact_message).with(message: message).and_return(true)

      subject
    end
  end

  context 'the message is not in a final state' do
    let(:error) { Twilio::REST::RestError.new('Not Complete', 20009, 400) }

    it 'retries the job' do
      expect(SMSService.instance).to receive(:redact_message).exactly(4).times.with(message: message).and_raise(error)
      expect(SMSService.instance).to receive(:redact_message).with(message: message).and_return(true)

      subject
    end
  end
end
