require "rails_helper"

describe NotificationMailer, type: :mailer do
  describe '#message_notification' do
    let(:user) { build(:user) }
    let(:message) { create(:message, created_at: Time.zone.local(2012, 07, 11, 20, 10, 0)) }
    let(:mail) { NotificationMailer.message_notification(user, message) }
    let(:client) { message.client }
    it "renders the headers" do
      expect(mail.subject).to eq("New text message from #{client.first_name} #{client.last_name} on ClientComm")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include('sent you a text')
      expect(mail.body.encoded).to include(message.created_at.strftime('7/11'))
      expect(mail.body.encoded).to include(message.created_at.strftime('8:10PM'))
      expect(mail.body.encoded).to include(message.body)
      expect(mail.body.encoded).to include(client_messages_url(message))
    end
  end
end
