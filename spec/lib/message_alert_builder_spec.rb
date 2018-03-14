require 'rails_helper'

describe MessageAlertBuilder do
  describe '#build' do
    let(:reporting_relationship_path) { 'some client messages path' }
    let(:clients_path) { 'all clients path' }
    let(:user) { create :user }
    subject do
      described_class.build_alert(
        user: user,
        reporting_relationship_path: reporting_relationship_path,
        clients_path: clients_path
      )
    end

    specify 'when there are no unread messages' do
      expect(subject).to be_nil
    end

    specify 'when there is one unread message' do
      client = create :client, user: user, first_name: 'Senay', last_name: 'Haylom'
      create :message, user: user, client: client, inbound: true, read: false

      expect(subject).to eq({
                              text: 'You have 1 unread message from Senay Haylom',
                              link_to: reporting_relationship_path
                            })
    end

    specify 'when there is more than one unread message from the same client' do
      client = create :client, user: user, first_name: 'Anna', last_name: 'Futsum'
      create :message, user: user, client: client, inbound: true, read: false
      create :message, user: user, client: client, inbound: true, read: false

      expect(subject).to eq({
                              text: 'You have 2 unread messages from Anna Futsum',
                              link_to: reporting_relationship_path
                            })
    end

    specify 'when there is more than one unread message from multiple clients' do
      clientone = create :client, user: user, first_name: 'Aziz', last_name: 'Yonas'
      clienttwo = create :client, user: user, first_name: 'Mustafa', last_name: 'Semhar'
      create :message, user: user, client: clientone, inbound: true, read: false
      create :message, user: user, client: clienttwo, inbound: true, read: false
      expect(subject).to eq({
                              text: 'You have 2 unread messages',
                              link_to: clients_path
                            })
    end

    specify 'when there are a mixture of read and unread messages from a client' do
      client = create :client, user: user, first_name: 'Luwam', last_name: 'Sayid'
      create :message, user: user, client: client, inbound: true, read: true
      create :message, user: user, client: client, inbound: true, read: true
      create :message, user: user, client: client, inbound: true, read: false
      expect(subject).to eq({
                              text: 'You have 1 unread message from Luwam Sayid',
                              link_to: reporting_relationship_path
                            })
    end

    specify "when there are unread messages for a different user's clients" do
      other_user = create :user
      client = create :client, user: other_user, first_name: 'Demet', last_name: 'Zula'
      create :message, user: other_user, client: client, inbound: true, read: false
      create :message, user: other_user, client: client, inbound: true, read: false
      expect(subject).to eq nil
    end

    context 'there are multiple clients' do
      let(:clientone) { create :client, user: user, first_name: 'Zarka', last_name: 'Viktor' }
      let(:clienttwo) { create :client, user: user, first_name: 'Thury', last_name: 'Izsak' }
      let(:clientthree) { create :client, user: user, first_name: 'Asztalos', last_name: 'Bernadett' }

      before do
        create :message, user: user, client: clientone, inbound: true, read: false
        create :message, user: user, client: clienttwo, inbound: true, read: false
        create :message, user: user, client: clientthree, inbound: true, read: false
      end

      context 'only one is inactive' do
        specify 'when there are unread messages on a deactivated client' do
          ReportingRelationship.find_by(user: user, client: clienttwo).update!(active: false)
          expect(subject).to eq({
                                  text: 'You have 2 unread messages',
                                  link_to: clients_path
                                })
        end
      end

      context 'only one is active' do
        specify 'when there are unread messages on a deactivated client' do
          ReportingRelationship.find_by(user: user, client: clientone).update!(active: false)
          ReportingRelationship.find_by(user: user, client: clienttwo).update!(active: false)
          expect(subject).to eq({
                                  text: 'You have 1 unread message from Asztalos Bernadett',
                                  link_to: reporting_relationship_path
                                })
        end
      end
    end
  end
end
