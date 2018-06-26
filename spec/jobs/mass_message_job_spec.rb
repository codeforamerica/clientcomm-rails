require 'rails_helper'

RSpec.describe SendMassMessageJob, active_job: true, type: :job do
  describe '#perform' do
    let(:department) { create :department }
    let(:user) { create :user, department: department }
    let!(:client_1) { create :client, user: user }
    let!(:client_2) { create :client, user: user }
    let!(:client_3) { create :client, user: user }
    let(:rr_1) { ReportingRelationship.find_by(user: user, client: client_1)  }
    let(:rr_2) { ReportingRelationship.find_by(user: user, client: client_2)  }
    let(:rr_3) { ReportingRelationship.find_by(user: user, client: client_3)  }
    let(:message_body) { 'hello this is message one' }
    let(:rrs) { [rr_1.id, rr_3.id] }
    let(:send_at) { Time.zone.now }

    subject do
      SendMassMessageJob.perform_now(
        rrs: rrs,
        body: message_body,
        send_at: send_at.to_s
      )
    end

    it 'sends message to multiple rrs' do
      subject

      expect(ScheduledMessageJob).to have_been_enqueued.twice
      expect(user.messages.count).to eq 2
      expect(client_1.messages.count).to eq 1
      expect(client_1.messages.first.body).to eq message_body
      expect(client_1.messages.first.number_from).to eq department.phone_number
      expect(client_2.messages.count).to eq 0
      expect(client_3.messages.count).to eq 1
      expect(client_3.messages.first.body).to eq message_body
      expect(client_3.messages.first.number_from).to eq department.phone_number
    end

    it 'sends an analytics event for each message in mass message' do
      subject
      expect_analytics_events(
        'message_send' => {
          'mass_message' => true
        }
      )

      expect_analytics_event_sequence(
        'message_send',
        'message_send'
      )
    end

    context 'a send_at date is set' do
      let(:send_at) { Time.zone.now.change(sec: 0, usec: 0) + 2.days }

      it 'sends message to multiple rrs at the right time' do
        subject

        expect(ScheduledMessageJob).to have_been_enqueued.at(send_at).twice
        expect(client_1.messages.first.send_at).to eq send_at
        expect(client_3.messages.first.send_at).to eq send_at
      end

      it 'sends an analytics event for each message in mass message' do
        subject
        expect_analytics_events(
          'message_scheduled' => {
            'mass_message' => true
          }
        )

        expect_analytics_event_sequence(
          'message_scheduled',
          'message_scheduled'
        )
      end
    end
  end
end
