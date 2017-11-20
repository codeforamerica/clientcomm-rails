require 'rails_helper'

describe ScheduledMessageJob, active_job: true, type: :job do
  let(:count) { 4 }
  let(:link_html) { 'scheduled_messages_link_partial' }
  let(:scheduled_messages) { double('scheduled_messages', count: count) }
  let(:send_at_time) { Time.now.tomorrow }
  let(:message) { create :message, send_at: send_at_time }

  subject do
    perform_enqueued_jobs { ScheduledMessageJob.perform_later(message: message, send_at: send_at_time.to_i, callback_url: 'whocares.com') }
  end

  it 'calls SMSService when performed' do
    expect(SMSService.instance).to receive(:send_message).with(message: message, callback_url: 'whocares.com')
    expect_any_instance_of(ScheduledMessageJob).to receive(:scheduled_messages)
      .with(client: message.client)
      .and_return(scheduled_messages)

    expect(MessagesController).to receive(:render)
      .with(partial: 'messages/scheduled_messages_link', locals: { count: count, client: message.client })
      .and_return(link_html)

    expect(ActionCable.server).to receive(:broadcast)
      .with("scheduled_messages_#{message.user.id}_#{message.client.id}", link_html: link_html, count: count)

    subject

    message.reload

    expect(message.client.last_contacted_at).to be_within(0.1.seconds).of send_at_time
  end

  shared_examples 'does not send' do
    it 'does not send the message' do
      expect(SMSService.instance).to_not receive(:send_message)
      expect_any_instance_of(ScheduledMessageJob).to_not receive(:scheduled_messages)

      expect(MessagesController).to_not receive(:render)

      expect(ActionCable.server).to_not receive(:broadcast)

      subject
    end
  end

  context 'When rescheduled' do
    let(:message) { create :message, send_at: Time.now }

    it_behaves_like 'does not send'
  end

  context 'When already sent' do
    let(:message) { create :message, sent: true }

    it_behaves_like 'does not send'
  end
end
