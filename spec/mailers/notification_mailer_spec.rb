require "rails_helper"

describe NotificationMailer, type: :mailer do
  describe '#message_notification' do
    let(:user) {build(:user)}
    let(:client) {build(:client, id: 123456789)}
    let(:attachment) {build :attachment}
    let(:message) {create(:message, client: client, created_at: Time.zone.local(2012, 07, 11, 20, 10, 0), attachments: [attachment])}
    let(:mail) {NotificationMailer.message_notification(user, message)}

    shared_examples_for 'notification email' do
      it 'renders the headers' do
        expect(mail.subject).to eq("New text message from #{client.first_name} #{client.last_name} on ClientComm")
        expect(mail.to).to eq([user.email])
      end

      it 'renders the body' do
        expect(subject).to include('sent you a text')
        expect(subject).to include(message.created_at.strftime('7/11'))
        expect(subject).to include(message.created_at.strftime('8:10PM'))
        expect(subject).to include(message.body)
        expect(subject).to include(client_messages_url(client))
      end
    end

    context 'html part' do
      subject {mail.body.encoded}

      it_behaves_like 'notification email'

      it 'renders the attachment' do
        expect(subject).to include(attachment.url)
      end
    end

    context 'text part' do
      subject {mail.text_part.body}

      it_behaves_like 'notification email'

      it 'shows a message for an attachment' do
        expect(subject).to include '[Image attached, view on ClientComm]'
      end
    end
  end
end
