require 'rails_helper'

describe FrontImport, front: true do
  before do
    WebMock.disable!
  end

  after do
    WebMock.enable!
  end

  let(:front_token) { ENV['FRONT_AUTH_TOKEN'] }
  let(:front_import) { described_class.new(front_token: front_token) }
  let(:user) { create(:user) }

  describe '#import' do
    let(:user_email) { 'joannemorales@workforce.org' }

    subject { front_import.import(email: user_email) }

    it 'grabs contact from Front' do
      subject

      user = User.first
      expect(user.full_name).to eq 'Joanne Morales'
      expect(user.email).to eq user_email
    end

    context 'invalid inbox' do
      let(:user_email) { 'estelamolina@workforce.org' }

      it 'fails' do
        expect { subject }.to raise_error StandardError
      end
    end
  end

  describe '#import_messages' do
    let(:conversation_id) { 'cnv_6vqm67' }
    let!(:some_client) { create :client, phone_number: '+16198449469' }

    subject { front_import.import_messages(user: user, conversation_id: conversation_id) }

    it 'saves a list of messages to the database' do
      subject

      received_message = Message.first
      expect(received_message.client).to eq some_client
      expect(received_message.user).to eq user
      expect(received_message.body).to eq 'Ok'
      expect(received_message.number_from).to eq '+16198449469'
      expect(received_message.number_to).to eq '+15614492331'
      expect(received_message.inbound).to be_truthy
      expect(received_message.created_at).to eq Time.zone.local(2017, 8, 15, 16, 4, 8, 3999)
      expect(received_message.send_at).to eq Time.zone.local(2017, 8, 15, 16, 4, 8, 3999)
      expect(received_message.sent).to be_truthy
      expect(received_message.read).to be_truthy

      sent_message = Message.second
      expect(sent_message.client).to eq some_client
      expect(sent_message.user).to eq user
      expect(sent_message.body).to eq 'Great see you then😃'
      expect(sent_message.number_from).to eq '+15614492331'
      expect(sent_message.number_to).to eq '+16198449469'
      expect(sent_message.inbound).to be_falsey
      expect(sent_message.created_at).to eq Time.zone.local(2017, 8, 15, 15, 34, 47, 538000)
      expect(sent_message.send_at).to eq Time.zone.local(2017, 8, 15, 15, 34, 47, 538000)
      expect(sent_message.sent).to be_truthy
      expect(received_message.read).to be_truthy

      expect(Message.count).to eq 12
    end

    context 'users changed number of client' do
      let(:conversation_id) { 'cnv_61jpvv' }
      let!(:some_client) { create :client, phone_number: '+18588694853' }

      subject { front_import.import_messages(user: user, conversation_id: conversation_id) }

      it 'sets the correct client on each message' do
        subject

        expect(some_client.messages.count).to eq 3
      end
    end
  end

  describe '#conversations' do
    let(:inbox_id) { 'inb_1zhv' }

    subject { front_import.conversations(user: user, inbox_id: inbox_id) }

    it 'gets a list of conversation ids' do
      expect(subject).to include('cnv_6vqm67')
    end

    context 'there are more than 100 conversations' do
      let(:inbox_id) { 'inb_23px' }
      it 'paginates correctly' do
        expect(subject).to include('cnv_5swx7z')
      end
    end
  end

  describe '#create_contact_from_id' do
    subject { front_import.create_contact_from_id(user: user, contact_id: contact_id) }

    context 'contact has a name' do
      let(:contact_id) { 'ctc_21b6up' }

      it 'adds contact to db' do
        subject

        client = Client.first

        expect(client.phone_number).to eq '+16199886354'
        expect(client.first_name).to eq 'Ronald'
        expect(client.last_name).to eq 'Loper'
        expect(client.user).to eq user
      end

      context 'contact has only one name' do
        let(:contact_id) { 'ctc_26agf1' }

        it 'adds contact to db and ignores first name' do
          subject

          client = Client.first

          expect(client.phone_number).to eq '+16193868913'
          expect(client.last_name).to eq 'Rhoten'
          expect(client.user).to eq user
        end

      end
    end

    context 'contact has no name' do
      let(:contact_id) { 'ctc_2codpz' }
      let(:phone_number) { '+16198624157' }

      it 'adds contact to db' do
        subject

        client = Client.first

        expect(client.phone_number).to eq phone_number
        expect(client.last_name).to eq phone_number
        expect(client.user).to eq user
      end
    end

    context 'contact already exists' do
      let(:contact_id) { 'ctc_2eh605' }
      let(:phone_number) { '+113057313456' }

      before do
        create :client, phone_number: phone_number
      end

      it 'does nothing' do
        expect(Client.count).to eq 1

        subject

        expect(Client.count).to eq 1
      end
    end
  end

  describe '#create_contact_from_phone_number' do
    subject { front_import.create_contact_from_phone_number(user: user, phone_number: phone_number) }

    let(:phone_number) { '+17605553329' }

    it 'adds contact to db' do
      subject

      client = Client.first

      expect(client.phone_number).to eq phone_number
      expect(client.last_name).to eq phone_number
      expect(client.user).to eq user
    end
  end

  describe '#inboxes' do
    subject { front_import.inboxes }

    it 'gets inboxes' do
      inboxes =
          {
              'CfA Concierge' => 'inb_1zht'
          }

      expect(subject).to include inboxes
    end

    context 'token is not provided' do
      let(:front_token) { nil }

      it 'raises an exception' do
        expect { subject }.to raise_error StandardError
      end
    end
  end
end
