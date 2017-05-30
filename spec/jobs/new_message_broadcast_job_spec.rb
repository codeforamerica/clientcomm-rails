require 'rails_helper'

RSpec.describe NewMessageBroadcastJob, type: :job do
  describe 'broadcast job' do
    let!(:user) { create :user }
    let!(:client) { create :client, :user => user }

    describe 'after a create/commit' do
      it 'receives a perform_later' do
        # stub the message broadcast job
        job_class = class_double("NewMessageBroadcastJob").as_stubbed_const
        # expect the job to be sent when the message is created
        expect(job_class).to receive(:perform_later).with(instance_of(Message))
        # create a message to trigger the after_create_commit
        create :message, :user => user, :client => client
      end
    end
  end
end
