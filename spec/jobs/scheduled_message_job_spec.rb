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

  subject do
    perform_enqueued_jobs { ScheduledMessageJob.perform_later(message: message, send_at: send_at_time.to_i, callback_url: 'whocares.com') }
  end

  it 'calls SMSService when performed' do
    expect(SMSService.instance).to receive(:send_message).with(message: message, callback_url: 'whocares.com')

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
