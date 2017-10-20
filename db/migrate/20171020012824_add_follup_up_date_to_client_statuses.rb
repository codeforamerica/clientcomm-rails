class AddFollupUpDateToClientStatuses < ActiveRecord::Migration[5.1]
  def change
    add_column :client_statuses, :followup_date, :integer

    if (active_status = ClientStatus.find_by_name('Active'))
      active_status.update!(followup_date: 25)
    end

    if (training_status = ClientStatus.find_by_name('Training'))
      training_status.update!(followup_date: 25)
    end

    if (exited_status = ClientStatus.find_by_name('Exited'))
      exited_status.update!(followup_date: 85)
    end

    change_column_null :client_statuses, :followup_date, false
  end
end
