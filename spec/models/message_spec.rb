require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'relationships' do
    it do
      should belong_to :client
      should belong_to :user
      should have_many :attachments
    end

    it do
      should validate_presence_of(:send_at)
        .with_message("That date didn't look right.")
    end

    context 'validating body of message' do
      it 'does not validate message with empty body with no attachments' do
        m = Message.create(body: '')
        expect(m.errors[:body].present?).to eq true
      end

      it 'validates empty body with attachment' do
        m = build :message, body: ''
        m.attachments << build(:attachment)
        m.save!

        expect(m.save).to be_truthy
        expect(m.attachments.count).to eq 1
      end
    end

    it 'should validate that a message is scheduled in the future' do
      expect(Message.new.past_message?).to be_falsey

      expect(Message.new(send_at: Time.current - 1.day).past_message?).to be_truthy

      expect(Message.new(send_at: Time.current).past_message?).to be_falsey
      expect(Message.new(send_at: Time.current + 5.minutes).past_message?).to be_falsey

      message = Message.new(send_at: Time.current - 1.day)
      message.past_message?
      expect(message.errors[:send_at])
        .to include "You can't schedule a message in the past."
    end

    it 'validates that a messages cannot be scheduled a year in advance' do
      expect(Message.new(send_at: Time.current + 2.years).valid?).to be_falsey
    end
  end

  describe '#create_from_twilio' do
    context 'client does not exist' do
      let(:dept_phone_number) { '+17609996661' }
      let(:department) { create :department, phone_number: dept_phone_number }
      let(:unclaimed_user) { create :user, full_name: 'Unclaimed User', department: department }

      before do
        department.unclaimed_user = unclaimed_user
        department.save
      end

      it 'creates a new client with missing information' do
        unknown_number = '+19999999999'
        params = twilio_new_message_params from_number: unknown_number, to_number: dept_phone_number

        message = Message.create_from_twilio!(params)

        expect(message.user).to eq unclaimed_user
        expect(message.number_to).to eq dept_phone_number
        expect(message.number_from).to eq unknown_number
        expect(message.inbound).to be_truthy
        expect(message.send_at).to be_present

        client = message.client
        expect(client.first_name).to be_nil
        expect(client.last_name).to eq unknown_number
        expect(client.phone_number).to eq unknown_number
        expect(client.users).to include unclaimed_user
      end
    end

    context 'client exists' do
      let(:dept_phone_number) { '+17609996661' }
      let!(:user) { create :user, dept_phone_number: dept_phone_number }
      let!(:client) { create :client, users: [user] }

      it 'creates a message if proper params are sent' do
        params = twilio_new_message_params from_number: client.phone_number, to_number: dept_phone_number
        msg = Message.create_from_twilio!(params)
        expect(client.messages.last).to eq msg
      end

      context 'there is an attachment' do
        let(:params) do
          twilio_new_message_params(
            from_number: client.phone_number,
            to_number: dept_phone_number,
            msg_txt: body
          ).merge(NumMedia: 2,
                  MediaUrl0: 'http://cats.com/fluffy_cat.png',
                  MediaUrl1: 'http://cats.com/fluffy_cat.png',
                  MediaContentType0: 'text/png',
                  MediaContentType1: 'text/png')
        end

        before do
          stub_request(:get, 'http://cats.com/fluffy_cat.png')
            .to_return(status: 200,
                       body: File.read('spec/fixtures/fluffy_cat.jpg'),
                       headers: {
                         'Accept-Ranges' => 'bytes',
                         'Content-Length' => '4379330',
                         'Content-Type' => 'image/jpeg'
                       })
        end

        subject { Message.create_from_twilio!(params) }

        context 'message body is present' do
          let(:body) { 'some_body' }

          it 'creates a message with attachments' do
            attachments = subject.attachments.all
            expect(attachments.length).to eq 2

            attachments.each do |attachment|
              expect(attachment.media.exists?).to eq true
            end
          end
        end

        context 'message body is not present' do
          let(:body) { '' }

          it 'creates a message with no body but an attachment' do
            attachments = subject.attachments.all
            expect(attachments.length).to eq 2

            attachments.each do |attachment|
              expect(attachment.media.exists?).to eq true
            end
          end
        end
      end
    end
  end
end
