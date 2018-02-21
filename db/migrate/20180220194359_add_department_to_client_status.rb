class AddDepartmentToClientStatus < ActiveRecord::Migration[5.1]
  def change
    add_reference :client_statuses, :department, key: true
  end
end
