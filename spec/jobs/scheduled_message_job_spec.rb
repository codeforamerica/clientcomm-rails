require 'rails_helper'

describe ScheduledMessageJob, active_job: true, type: :job do
  let(:message){ create :message }
  let(:count) { 4 }
  let(:link_html) { 'scheduled_messages_link_partial' }
  let(:scheduled_messages) { double('scheduled_messages', count: count) }

  subject(:scheduled_job){ ScheduledMessageJob.perform_later(message: message, send_at: message.send_at.to_i, callback_url: 'whocares.com') }

  it 'calls SMSService when performed' do
    expect(SMSService.instance).to receive(:send_message).with(message: message, callback_url: 'whocares.com')
    expect_any_instance_of(ScheduledMessageJob).to receive(:scheduled_messages)
      .with(user: message.user)
      .and_return(scheduled_messages)

    expect(MessagesController).to receive(:render)
      .with(partial: 'messages/scheduled_messages_link', locals: {count: count, client: message.client})
      .and_return(link_html)

    expect(ActionCable.server).to receive(:broadcast)
      .with("scheduled_messages_#{message.client.id}", link_html: link_html, count: count)

    perform_enqueued_jobs { scheduled_job }
  end

  context "when scheduled for later" do
    let(:send_at_time) { Time.now.tomorrow }
    subject(:scheduled_job){ ScheduledMessageJob.perform_later(message: message, send_at: send_at_time.to_i, callback_url: 'whocares.com') }
    let(:message) {create :message, send_at: send_at_time}

    it 'calls SMSService when performed' do
      expect(SMSService.instance).to receive(:send_message).with(message: message, callback_url: 'whocares.com')
      expect_any_instance_of(ScheduledMessageJob).to receive(:scheduled_messages)
        .with(user: message.user)
        .and_return(scheduled_messages)

      expect(MessagesController).to receive(:render)
        .with(partial: 'messages/scheduled_messages_link', locals: {count: count, client: message.client})
        .and_return(link_html)

      expect(ActionCable.server).to receive(:broadcast)
        .with("scheduled_messages_#{message.client.id}", link_html: link_html, count: count)

      perform_enqueued_jobs { scheduled_job }
    end

    context 'When rescheduled' do
      let(:message) { create :message, send_at: Time.now }

      it 'does not send the message' do
        expect(SMSService.instance).to_not receive(:send_message)
        expect_any_instance_of(ScheduledMessageJob).to_not receive(:scheduled_messages)

        expect(MessagesController).to_not receive(:render)

        expect(ActionCable.server).to_not receive(:broadcast)
        perform_enqueued_jobs { scheduled_job }
      end
    end

    context 'When already sent' do
      let(:message) {create :message, send_at: send_at_time, sent: true}

      it 'ignores the message and does not send' do
        expect(SMSService.instance).to_not receive(:send_message)
        expect_any_instance_of(ScheduledMessageJob).to_not receive(:scheduled_messages)

        expect(MessagesController).to_not receive(:render)

        expect(ActionCable.server).to_not receive(:broadcast)
        perform_enqueued_jobs { scheduled_job }
      end
    end
  end
end
