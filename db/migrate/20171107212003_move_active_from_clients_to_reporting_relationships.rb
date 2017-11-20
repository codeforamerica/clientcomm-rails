class MoveActiveFromClientsToReportingRelationships < ActiveRecord::Migration[5.1]
  def up
    Client.all.find_each do |client|
      ReportingRelationship.find_or_create_by(
        user_id: client['user_id'],
        client: client
      ) do |rr|
        rr.active = client.active
      end
    end
  end
end
