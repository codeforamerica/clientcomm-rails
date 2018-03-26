load 'spec/rails_helper.rb'
load 'db/migrate/20180314000756_add_reporting_relationship_to_message.rb'

describe AddReportingRelationshipToMessage do
  before do
    ActiveRecord::Migrator.migrate Rails.root.join("db/migrate"), 20180311020035
    Message.reset_column_information
  end

  describe '#up' do
    let(:user) { create :user }
    let(:client) { create :client, users: [user] }

    subject do
      ActiveRecord::Migrator.migrate Rails.root.join("db/migrate"), 20180314000756
      Message.reset_column_information
    end

    it 'message is linked to the proper reporting relationship' do
      # Inline so that the `before` migration runs first
      message = Message.create(user: user,
                               client: client,
                               number_to: '+17605559331',
                               number_from: '+17605556230',
                               send_at: Time.now)

      rr = ReportingRelationship.find_by(user: user, client: client)

      subject
      expect(message.reload.reporting_relationship).to eq(rr)
      expect(message.reload.original_reporting_relationship).to eq(rr)
    end

    context 'has missing reporting relationships' do
      let(:client) { create :client }

      it 'message is linked to the proper reporting relationship' do
        # Inline so that the `before` migration runs first
        message = Message.create(user: user,
                                 client: client,
                                 number_to: '+17605559331',
                                 number_from: '+17605556230',
                                 send_at: Time.now)


        expect(client.users).to_not include(user)
        subject
        expect(client.reload.users).to include(user)

        rr = ReportingRelationship.find_by(user: user, client: client)
        expect(rr).to_not be_active

        expect(message.reload.reporting_relationship).to eq(rr)
        expect(message.reload.original_reporting_relationship).to eq(rr)
      end
    end
  end
end
