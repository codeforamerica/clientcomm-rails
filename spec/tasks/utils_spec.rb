require 'rails_helper'
require 'rake'

describe 'utils rake tasks' do
  before do
    Rake.application.rake_require 'tasks/utils'
    Rake::Task.define_task(:environment)
  end

  describe 'utils:get_status', type: :request do
    subject {
      Rake::Task['utils:get_status'].reenable
      Rake::Task['utils:get_status'].invoke(*sids)
    }

    context 'no sids are passed' do
      let(:sids) { [] }

      it 'outputs an error with instructions' do
        expect { subject }.to output(/no Twilio SIDs passed/).to_stdout
      end
    end

    context 'the message exists' do
      let(:message) { create :text_message, twilio_status: 'delivered', inbound: false, read: true }
      let(:sids) { [message.twilio_sid] }

      it 'outputs the status of the message' do
        expected_output = <<~OUTPUT
          getting statuses for 1 Twilio SIDs
          ==================================
              sid: #{message.twilio_sid}
           status: ✅ DELIVERED
          inbound:    false 📤
             read: 📭 true
          ----------

          0 SIDs not found
        OUTPUT

        expect { subject }.to output(expected_output).to_stdout
      end
    end

    context 'the message does not exist' do
      let(:bad_sid) { SecureRandom.hex(17) }
      let(:sids) { [bad_sid] }

      it 'outputs an error message' do
        expected_output = <<~OUTPUT
          getting statuses for 1 Twilio SIDs
          ==================================
          🔥 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 🔥
          🔥 #{bad_sid} WAS NOT FOUND 🔥
          🔥 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 🔥
          ----------

          1 SIDs not found
          ----------
          '#{bad_sid}'
          ----------
          #{bad_sid}
          ----------
          #{bad_sid}
        OUTPUT

        expect { subject }.to output(expected_output).to_stdout
      end
    end

    context 'the sid represents a telephone call' do
      let(:voice_sid) { "CA#{SecureRandom.hex(15)}" }
      let(:sids) { [voice_sid] }

      it 'outputs an error message' do
        expected_output = <<~OUTPUT
          getting statuses for 1 Twilio SIDs
          ==================================
          📞 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 📞
          📞 #{voice_sid} IS PHONE CALL 📞
          📞 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 📞
          ----------

          1 SIDs not found
          ----------
          '#{voice_sid}'
          ----------
          #{voice_sid}
          ----------
          #{voice_sid}
        OUTPUT

        expect { subject }.to output(expected_output).to_stdout
      end
    end

    context 'multiple messages exist' do
      let(:message_one) { create :text_message, twilio_status: 'undelivered', inbound: false, read: true }
      let(:message_two) { create :text_message, twilio_status: 'sent', inbound: false, read: true }
      let(:message_three) { create :text_message, twilio_status: 'received', inbound: true, read: false }
      let(:sids) { [message_one.twilio_sid, message_two.twilio_sid, message_three.twilio_sid] }

      it 'outputs the status of the message' do
        expected_output = <<~OUTPUT
          getting statuses for 3 Twilio SIDs
          ==================================
              sid: #{message_one.twilio_sid}
           status: ❌ UNDELIVERED
          inbound:    false 📤
             read: 📭 true
          ----------
              sid: #{message_two.twilio_sid}
           status: 🤔 SENT
          inbound:    false 📤
             read: 📭 true
          ----------
              sid: #{message_three.twilio_sid}
           status: ✅ RECEIVED
          inbound: 📥 true
             read:    false 📬
          ----------

          0 SIDs not found
        OUTPUT

        expect { subject }.to output(expected_output).to_stdout
      end
    end
  end

  describe 'utils:insert_message', type: :request, active_job: true do
    let(:user) { create :user }
    let!(:client) { create :client, user: user }
    let(:rr) { ReportingRelationship.find_by(user: user, client: client) }
    let(:twilio_client) { FakeTwilioClient.new account_sid, auth_token }
    let(:account_sid) { 'some_sid' }
    let(:auth_token) { 'some_token' }
    let(:message_sid) { SecureRandom.hex(17) }
    let(:status) { 'received' }
    let(:manual_body) { 'This is a message body sent to the task.' }
    let(:twilio_body) { 'This is the message body sent by Twilio.' }
    let(:num_media) { 0 }
    let(:media) { double('message_media', list: []) }
    let(:twilio_message) {
      double(
        'twilio_message',
        from: client.phone_number,
        to: user.department.phone_number,
        sid: message_sid,
        status: status,
        body: twilio_body,
        num_media: num_media,
        media: media
      )
    }

    subject {
      Rake::Task['utils:insert_message'].reenable
      Rake::Task['utils:insert_message'].invoke(message_sid, manual_body)
    }

    before do
      @account_sid = ENV['TWILIO_ACCOUNT_SID']
      @auth_token = ENV['TWILIO_AUTH_TOKEN']

      ENV['TWILIO_ACCOUNT_SID'] = account_sid
      ENV['TWILIO_AUTH_TOKEN'] = auth_token

      allow(Twilio::REST::Client).to receive(:new).with(account_sid, auth_token).and_return(twilio_client)
    end

    after do
      ENV['TWILIO_ACCOUNT_SID'] = @account_sid
      ENV['TWILIO_AUTH_TOKEN'] = @auth_token
    end

    context 'no sid or body is passed to the task' do
      let(:message_sid) { nil }
      let(:manual_body) { nil }

      it 'responds with an error' do
        expect { subject }.to output(/no message sid passed/).to_stdout

        expect(Message.where(twilio_sid: message_sid).length).to eq 0
      end
    end

    context 'the message does not already exist' do
      before do
        allow(MessageHandler).to receive(:handle_new_message)

        expect_any_instance_of(FakeTwilioClient).to receive(:messages)
          .with(message_sid)
          .and_return(double('messages', fetch: twilio_message))
      end

      context 'a new message body is passed to the task' do
        it 'creates the message with the new message body' do
          subject

          new_message = Message.find_by(twilio_sid: message_sid)

          expect(MessageHandler).to have_received(:handle_new_message)
            .with(message: new_message)

          expect(new_message).to_not be_nil
          expect(new_message.twilio_status).to eq status
          expect(new_message.number_to).to eq user.department.phone_number
          expect(new_message.number_from).to eq client.phone_number
          expect(new_message.body).to eq manual_body
          expect(new_message.inbound).to be_truthy
          expect(new_message.send_at).to be_present
        end
      end

      context 'no message body is passed to the task' do
        let(:manual_body) { nil }

        it 'creates the message with the twilio message body' do
          subject

          new_message = Message.find_by(twilio_sid: message_sid)

          expect(MessageHandler).to have_received(:handle_new_message)
            .with(message: new_message)

          expect(new_message).to_not be_nil
          expect(new_message.twilio_status).to eq status
          expect(new_message.number_to).to eq user.department.phone_number
          expect(new_message.number_from).to eq client.phone_number
          expect(new_message.body).to eq twilio_body
          expect(new_message.inbound).to be_truthy
          expect(new_message.send_at).to be_present
        end
      end

      context 'the message has an attachment' do
        let(:num_media) { 1 }
        let(:media_path) { '/fluffy_cat' }
        let(:media_item) { double('media_item', uri: "#{media_path}.json") }
        let(:media) { double('message_media', list: [media_item]) }

        before do
          stub_request(:get, "https://api.twilio.com#{media_path}")
            .to_return(status: 200,
                       body: File.read('spec/fixtures/fluffy_cat.jpg'),
                       headers: {
                         'Accept-Ranges' => 'bytes',
                         'Content-Length' => '4379330',
                         'Content-Type' => 'image/jpeg'
                       })
        end

        it 'creates the message with an attachment' do
          subject

          new_message = Message.find_by(twilio_sid: message_sid)

          expect(MessageHandler).to have_received(:handle_new_message)
            .with(message: new_message)

          expect(new_message).to_not be_nil
          expect(new_message.twilio_status).to eq status
          expect(new_message.number_to).to eq user.department.phone_number
          expect(new_message.number_from).to eq client.phone_number
          expect(new_message.body).to eq manual_body
          expect(new_message.inbound).to be_truthy
          expect(new_message.send_at).to be_present
          expect(new_message.attachments.count).to eq(1)
          expect(new_message.attachments.first.media_content_type).to eq('image/jpeg')
        end
      end
    end

    context 'the message already exists' do
      let!(:message) { create :text_message, twilio_sid: message_sid }

      it 'does not create a new message' do
        expect { subject }.to output(/message with that sid already exists!/).to_stdout

        expect(Message.where(twilio_sid: message_sid).length).to eq 1
      end
    end
  end
end
