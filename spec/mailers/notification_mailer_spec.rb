require 'rails_helper'

describe NotificationMailer, type: :mailer do
  describe '#message_notification' do
    let(:user) { build(:user) }
    let(:client) { build(:client, id: 123456789) }
    let(:attachment) { build :attachment }
    let(:message) { create(:message, client: client, created_at: Time.zone.local(2012, 07, 11, 20, 10, 0), attachments: [attachment]) }
    let(:mail) { NotificationMailer.message_notification(user, message) }

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
      subject { mail.body.encoded }

      it_behaves_like 'notification email'

      it 'renders the attachment' do
        expect(subject).to include(attachment.media.url)
      end
    end

    context 'text part' do
      subject { mail.text_part.body }

      it_behaves_like 'notification email'

      it 'shows a message for an attachment' do
        expect(subject).to include '[Image attached, view on ClientComm]'
      end
    end
  end

  describe '#client_transfer_notification' do
    let(:current_user) { create(:user) }
    let(:previous_user) { create(:user) }
    let(:client) { create(:client) }
    let(:mail) do
      NotificationMailer.client_transfer_notification(
        current_user: current_user,
        previous_user: previous_user,
        client: client
      )
    end

    shared_examples_for 'client_transfer_notification' do
      it 'renders the headers' do
        expect(mail.subject).to eq('You have a new client on ClientComm')
        expect(mail.to).to eq([current_user.email])
      end

      it 'renders the body' do
        expect(subject).to include('An administrator has transferred')
        expect(subject).to include(client.full_name)
        expect(subject).to include(client.phone_number)
        expect(subject).to include(previous_user.full_name)
        expect(subject).to include(client_messages_url(client))
      end
    end

    context 'html part' do
      subject { mail.body.encoded }

      it_behaves_like 'client_transfer_notification'
    end

    context 'text part' do
      subject { Premailer::Rails::Hook.perform(mail).text_part.body }

      it_behaves_like 'client_transfer_notification'
    end
  end

  describe 'client_edit_notification' do
    let(:user1) { create :user, email: 'user1@user1.com' }
    let(:user2) { create :user, email: 'user2@user2.com' }

    # for fun, call this number (yes it's real, no it's not a prank)
    let(:client) { create :client, users: [user1, user2], first_name: 'John', last_name: 'Smith', phone_number: '(844) 387-6962' }

    context 'name change' do
      subject do
        NotificationMailer.client_edit_notification(
          notified_user: user1,
          editing_user: user2,
          full_name: 'Joe Schmoe',
          client: client
        )
      end

      it 'renders the body' do
        expect(subject.to).to eq(%w[user1@user1.com])
        expect(subject.body.to_s)
          .to include("Joe Schmoe's name is now")

        url = url_for(controller: 'messages', action: 'index', client_id: client.id)
        expect(subject.body.to_s)
          .to have_link('John Smith', href: url)
      end
    end

    context 'phone change' do
      subject do
        NotificationMailer.client_edit_notification(
          notified_user: user1,
          editing_user: user2,
          phone_number: '867-5309',
          client: client
        )
      end

      it 'renders the body' do
        # expect(subject.to).to eq(%w[user1@user1.com])
        # expect(subject.body.encoded)
        #   .to include("#{link_to client.full_name, client_path(client)}'s phone_number has changed from 867-5309 to (844) 387-6962")
      end
    end

    context 'both change' do
      subject do
        NotificationMailer.client_edit_notification(
          notified_user: user1,
          editing_user: user2,
          full_name: 'Joe Schmoe',
          phone_number: '867-5309',
          client: client
        )
      end

      it 'renders the body' do
        # expect(subject.to).to eq(%w[user1@user1.com])
        # expect(subject.body.encoded)
        #   .to include("#{link_to client.full_name, client_path(client)}'s phone_number has changed from 867-5309 to (844) 387-6962")
      end
    end
  end
end
