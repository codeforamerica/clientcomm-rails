require 'rails_helper'

RSpec.describe MessageBroadcastJob, active_job: true, type: :job do
  describe '#perform' do
    let!(:user) { create :user }
    let!(:client) { create :client, user: user }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let!(:message) { create :text_message, reporting_relationship: rr }

    it 'queues a job' do
      described_class.perform_later(message: message)
      expect(described_class).to have_been_enqueued
    end

    it 'the job is in the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end

    it 'running the job sends the expected data to ActionCable' do
      assert_no_performed_jobs
      # the first value in double is for reference
      mock_server = double('ActionCable.server', broadcast: nil)
      allow(ActionCable).to receive(:server).and_return(mock_server)
      perform_enqueued_jobs do
        described_class.perform_later(message: message)
        assert_performed_jobs 1
      end

      # validate the data that was sent to our mock server
      message_partial = MessagesController.render(
        partial: 'messages/message',
        locals: { message: message }
      )

      expect(mock_server).to have_received(:broadcast).once.with(
        "messages_#{user.id}_#{message.client.id}",
        message_html: message_partial,
        message_dom_id: "message_#{message.id}",
        message_id: message.id
      )
      expect(mock_server).to have_received(:broadcast).once.with("clients_#{user.id}", {})
    end
  end
end
