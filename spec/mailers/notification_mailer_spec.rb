require 'rails_helper'

describe NotificationMailer, type: :mailer do
  describe '#message_notification' do
    let(:user) { create(:user, full_name: 'Norris Lesage') }
    let(:client) { create(:client, id: 123456789, user: user) }
    let(:rr) { ReportingRelationship.find_by(client: client, user: user) }
    let(:media_path) { 'spec/fixtures/fluffy_cat.jpg' }
    let(:attachment) { build :attachment, media: File.new(media_path) }
    let(:message) { create(:text_message, reporting_relationship: rr, created_at: Time.zone.local(2012, 07, 11, 20, 10, 0), attachments: [attachment]) }
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
        expect(subject).to include(reporting_relationship_url(rr))
      end
    end

    context 'an image is sent' do
      subject { mail.body.encoded }

      it_behaves_like 'notification email'

      it 'attaches files to email' do
        expect(mail.attachments.count).to eq 1
        expect(mail.attachments[0].content_type).to include 'image/jpeg'
        expect(mail.attachments[0].content_type).to include 'fluffy_cat'
        expect(subject).to include 'cid:'
      end
    end

    context 'an vcf file is sent' do
      let(:media_path) { 'spec/fixtures/cat_contact.vcf' }
      subject { mail.body.encoded }

      it_behaves_like 'notification email'

      it 'it renders view attachments txt' do
        expect(subject).to include 'Files sent via text are attached to this emai'
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
    let(:current_user) { create(:user, full_name: 'William Hearn') }
    let(:previous_user) { create(:user, full_name: 'Rita Johnston') }
    let(:client) { create(:client, first_name: 'Roger', last_name: 'Rabbit') }
    let(:mail) do
      NotificationMailer.client_transfer_notification(
        current_user: current_user,
        previous_user: previous_user,
        client: client
      )
    end

    before do
      create :reporting_relationship, user: current_user, client: client
      create :reporting_relationship, user: previous_user, client: client, active: false
    end

    shared_examples_for 'client_transfer_notification' do
      it 'renders the headers' do
        expect(mail.subject).to eq('You have a new client on ClientComm')
        expect(mail.to).to eq([current_user.email])
      end

      it 'renders the body' do
        expect(subject).to include("#{previous_user.full_name} has transferred")
        expect(subject).to include(client.full_name)
        expect(subject).to include(client.phone_number)
        expect(subject).to include(previous_user.full_name)
        rr = current_user.reporting_relationships.find_by(client: client)
        expect(subject).to include(reporting_relationship_url(rr))
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

  describe '#report_usage' do
    let(:end_date) { Time.zone.now }
    let(:email) { 'test@example.com' }
    let(:metrics) do
      [
        ['User One', '0', '0', '1', '1'],
        ['User Two', '3', '2', '4', '7'],
        ['User Three', '5', '1', '6', '11']
      ]
    end

    subject do
      NotificationMailer.report_usage(email, metrics, end_date.to_s)
    end

    it 'renders the email' do
      start_date = end_date - 7.days
      body = subject.body.encoded
      expect(subject.to).to contain_exactly(email)
      expect(subject.subject).to eq(I18n.t('report_mailer.subject', start_date: start_date.strftime('%-m/%-d/%y'), end_date: end_date.strftime('%-m/%-d/%y')))
      expect(body).to include("#{start_date.strftime '%-m/%-d/%y'} to #{end_date.strftime('%-m/%-d/%y')}")
      expect(body).to include('<td>8</td><td>3</td><td>11</td><td>19</td>')
      expect(subject.attachments.count).to eq 1
      csv = subject.attachments.first
      csv_content = CSV.new(csv.body.raw_source, headers: true)
      csv_content.each_with_index do |row, i|
        expect(metrics[i]).to eq(row.values_at)
      end
      expect(csv_content.headers).to eq([
                                          I18n.t('report_mailer.column_headers.name'),
                                          I18n.t('report_mailer.column_headers.outbound'),
                                          I18n.t('report_mailer.column_headers.scheduled'),
                                          I18n.t('report_mailer.column_headers.inbound'),
                                          I18n.t('report_mailer.column_headers.total')
                                        ])
    end
  end

  describe '#client_edit_notification' do
    let(:user1) { create :user, email: 'user1@user1.com', full_name: 'Patience Norbert' }
    let(:user2) { create :user, email: 'user2@user2.com', full_name: 'Gifford Bergeron' }
    let(:user3) { create :user, email: 'user3@user3.com', full_name: 'Gabrielle Meunier' }

    # for fun, call this number (yes it's real, no it's not a prank)
    let(:client) { create :client, users: [user1, user2, user3], first_name: 'John', last_name: 'Smith', phone_number: '+18443876962' }

    context 'name change' do
      subject do
        NotificationMailer.client_edit_notification(
          notified_user: user1,
          editing_user: user2,
          client: client,
          previous_changes: client.previous_changes
        )
      end

      before do
        allow(client).to receive(:previous_changes).and_return(
          'first_name' => %w[Joe John],
          'last_name' => %w[Schmoe Smith]
        )

        client.reporting_relationships.find_by(user: user3)
              .update(active: false)
      end

      it 'renders the body' do
        expect(subject.to).to eq(%w[user1@user1.com])
        expect(subject.body.to_s)
          .to include("Joe Schmoe's name is now")
        expect(subject.body.to_s).not_to include('phone number has changed from')

        rr = user1.reporting_relationships.find_by(client: client)
        url = reporting_relationship_url(rr)
        expect(subject.body.to_s)
          .to have_link('John Smith', href: url)

        expect(subject.body.to_s)
          .to include("will be shared with #{[user2.full_name].to_sentence}.")
      end

      context 'first_name only' do
        before do
          allow(client).to receive(:previous_changes).and_return(
            'first_name' => %w[Joe John]
          )
        end

        it 'renders the body' do
          expect(subject.to).to eq(%w[user1@user1.com])
          expect(subject.body.to_s)
            .to include("Joe Smith's name is now")
          expect(subject.body.to_s).not_to include('phone number has changed from')

          rr = user1.reporting_relationships.find_by(client: client)
          url = reporting_relationship_url(rr)
          expect(subject.body.to_s)
            .to have_link('John Smith', href: url)
        end
      end

      context 'last_name only' do
        before do
          allow(client).to receive(:previous_changes).and_return(
            'last_name' => %w[Schmoe Smith]
          )
        end

        it 'renders the body' do
          expect(subject.to).to eq(%w[user1@user1.com])
          expect(subject.body.to_s)
            .to include("John Schmoe's name is now")
          expect(subject.body.to_s).not_to include('phone number has changed from')

          rr = user1.reporting_relationships.find_by(client: client)
          url = reporting_relationship_url(rr)
          expect(subject.body.to_s)
            .to have_link('John Smith', href: url)
        end
      end
    end

    context 'phone change' do
      subject do
        NotificationMailer.client_edit_notification(
          notified_user: user1,
          editing_user: user2,
          client: client,
          previous_changes: client.previous_changes
        )
      end

      before do
        allow(client).to receive(:previous_changes).and_return(
          'phone_number' => ['+14088675309', '+18443876962']
        )
      end

      it 'renders the body' do
        expect(subject.to).to eq(%w[user1@user1.com])
        expect(subject.body.to_s)
          .to include('phone number has changed from (408) 867-5309 to (844) 387-6962')
        expect(subject.body.to_s).not_to include('name is now')

        rr = user1.reporting_relationships.find_by(client: client)
        url = reporting_relationship_url(rr)
        expect(subject.body.to_s)
          .to have_link("John Smith's", href: url)
      end
    end

    context 'both change' do
      subject do
        NotificationMailer.client_edit_notification(
          notified_user: user1,
          editing_user: user2,
          client: client,
          previous_changes: client.previous_changes
        )
      end

      before do
        allow(client).to receive(:previous_changes).and_return(
          'first_name' => %w[Joe John],
          'last_name' => %w[Schmoe Smith],
          'phone_number' => ['+14088675309', '+18443876962']
        )
      end

      it 'renders the body' do
        expect(subject.to).to eq(%w[user1@user1.com])
        expect(subject.body.to_s)
          .to include("Joe Schmoe's name is now")
        expect(subject.body.to_s)
          .to include('phone number has changed from (408) 867-5309 to (844) 387-6962')

        rr = user1.reporting_relationships.find_by(client: client)
        url = reporting_relationship_url(rr)
        expect(subject.body.to_s)
          .to have_link('John Smith', href: url)
        expect(subject.body.to_s)
          .to have_link("John Smith's", href: url)
      end
    end

    context 'neither phone number nor full name change' do
      subject do
        NotificationMailer.client_edit_notification(
          notified_user: user1,
          editing_user: user2,
          client: client,
          previous_changes: {}
        ).deliver_now
      end

      it 'logs that name and phone number did not change' do
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn).with('Phone number and name did not change.')
        subject
      end
    end
  end
end
