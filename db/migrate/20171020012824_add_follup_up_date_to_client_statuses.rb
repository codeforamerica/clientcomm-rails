class AddFollupUpDateToClientStatuses < ActiveRecord::Migration[5.1]
  def change
    add_column :client_statuses, :followup_date, :integer
    ClientStatus.reset_column_information

    active_status = ClientStatus.find_by(name: 'Active')
    if active_status
      active_status.update!(followup_date: 25)
    end

    training_status = ClientStatus.find_by(name: 'Training')
    if training_status
      training_status.update!(followup_date: 25)
    end

    exited_status = ClientStatus.find_by(name: 'Exited')
    if exited_status
      exited_status.update!(followup_date: 85)
    end

    change_column_null :client_statuses, :followup_date, false
  end
end
