class MakeFollowupDateNullableOnClientStatuses < ActiveRecord::Migration[5.1]
  def change
    change_column_null :client_statuses, :followup_date, true
  end
end
