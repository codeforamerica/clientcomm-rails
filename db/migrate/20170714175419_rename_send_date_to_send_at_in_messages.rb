class RenameSendDateToSendAtInMessages < ActiveRecord::Migration[5.0]
  def change
    rename_column :messages, :send_date, :send_at
  end
end
