require 'rails_helper'

describe ScheduledMessageJob, active_job: true, type: :job do
  let(:message){ create :message }
  let(:count) { 4 }
  let(:link_html) { 'scheduled_messages_link_partial' }
  let(:scheduled_messages) { double('scheduled_messages', count: count) }

  subject(:scheduled_job){ ScheduledMessageJob.perform_later(message: message, callback_url: 'whocares.com') }

  it 'calls SMSService when performed' do
    expect(SMSService.instance).to receive(:send_message).with(message: message, callback_url: 'whocares.com')
    expect_any_instance_of(ScheduledMessageJob).to receive(:scheduled_messages)
      .with(user: message.user)
      .and_return(scheduled_messages)

    expect(MessagesController).to receive(:render)
      .with(partial: 'messages/scheduled_messages_link', locals: {count: count})
      .and_return(link_html)

    expect(ActionCable.server).to receive(:broadcast)
      .with("scheduled_messages_#{message.client.id}", link_html: link_html, count: count)

    perform_enqueued_jobs { scheduled_job }
  end
end
