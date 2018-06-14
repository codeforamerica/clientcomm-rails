require 'rails_helper'

describe ScheduledMessageJob, active_job: true, type: :job do
  let(:count) { 1 }
  let(:link_html) { 'scheduled_messages_link_partial' }
  let(:scheduled_messages) { double('scheduled_messages', count: count) }
  let(:send_at_time) { Time.zone.now.tomorrow }
  let(:user) { create :user }
  let(:client) { create :client, users: [user] }
  let(:rr) { ReportingRelationship.find_by(client: client, user: user) }
  let(:message) { create :text_message, reporting_relationship: rr, send_at: send_at_time }
  let(:message_sid) { 'some sid' }
  let(:message_status) { 'some status' }
  let(:message_info) { { twilio_sid: message_sid, twilio_status: message_status } }

  subject do
    perform_enqueued_jobs do
      ScheduledMessageJob.perform_later(message: message, send_at: send_at_time.to_i, callback_url: 'whocares.com')
    end
  end

  before do
    allow(SMSService.instance).to receive(:send_message)
      .with(message: message, callback_url: 'whocares.com')
      .and_return(message_info)

    allow(MessageBroadcastJob).to receive(:perform_now).and_return(nil)
    allow(MessageRedactionJob).to receive(:perform_now).and_return(nil)
  end

  it 'calls SMSService when performed' do
    rr = message.client.reporting_relationship(user: message.user)
    expect(MessagesController).to receive(:render)
      .with(partial: 'reporting_relationships/scheduled_messages_link', locals: { count: count, rr: rr })
      .and_return(link_html)

    expect(ActionCable.server).to receive(:broadcast)
      .with("scheduled_messages_#{message.user.id}_#{message.client.id}", link_html: link_html, count: count)

    subject

    message.reload

    expect(message.client.last_contacted_at(user: message.user)).to be_within(0.1.seconds).of send_at_time
  end

  it 'updates the message with twilio info' do
    subject

    message.reload
    expect(message.twilio_sid).to eq(message_sid)
    expect(message.twilio_status).to eq(message_status)
    expect(message).to be_sent
  end

  it 'creates a MessageBroadcastJob' do
    expect(MessageBroadcastJob).to receive(:perform_now).with(
      message: message
    )

    subject
  end

  it 'creates a delayed MessageRedactionJob' do
    expect(MessageRedactionJob).to receive(:perform_later).with(
      message: message
    )

    subject
  end

  shared_examples 'does not send' do
    it 'does not send the message' do
      expect(SMSService.instance).to_not receive(:send_message)

      expect(MessagesController).to_not receive(:render)

      expect(ActionCable.server).to_not receive(:broadcast)

      subject
    end
  end

  context 'When rescheduled' do
    let(:message) { create :text_message, send_at: Time.zone.now }

    it_behaves_like 'does not send'
  end

  context 'When already sent' do
    let(:message) { create :text_message, sent: true }

    it_behaves_like 'does not send'
  end

  context 'retry on Twilio::REST::RequestError' do
    let(:error) { Twilio::REST::RestError.new('Not Found', 20404, 404) }

    it 'retries' do
      expect(SMSService.instance).to receive(:send_message).exactly(4).times.and_raise(error)
      expect(SMSService.instance).to receive(:send_message).and_return(message_info)

      subject
    end
  end

  context 'any other error occurs' do
    before do
      allow(SMSService.instance).to receive(:send_message).and_raise('Any Other Error')
    end

    it 'bubbles the error up' do
      expect { subject }.to raise_error('Any Other Error')
    end
  end

  context 'When the user is the unclaimed user' do
    before do
      user.department.update(unclaimed_user: user)
    end

    it 'logs that scheduled messages were sent' do
      expect(Rails.logger).to receive(:warn) do |&block|
        expect(block.call).to eq("Unclaimed user id: #{user.id} sent message id: #{message.id}")
      end

      subject
    end
  end
end
