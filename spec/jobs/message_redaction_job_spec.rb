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

  context 'redacting the message fails' do
    before do
      allow(SMSService.instance).to receive(:redact_message).and_return(false, true)
    end

    it 'requeues the message' do
      subject

      expect(SMSService.instance).to have_received(:redact_message).twice.with(message: message)
    end
  end
end
