class AddFollupUpDateToClientStatuses < ActiveRecord::Migration[5.1]
  def change
    add_column :client_statuses, :followup_date, :integer
    ClientStatus.reset_column_information

    active_status = ClientStatus.find_by(name: 'Active')
    active_status.update!(followup_date: 25) if active_status

    training_status = ClientStatus.find_by(name: 'Training')
    training_status.update!(followup_date: 25) if training_status

    exited_status = ClientStatus.find_by(name: 'Exited')
    exited_status.update!(followup_date: 85) if exited_status

    change_column_null :client_statuses, :followup_date, false
  end
end
