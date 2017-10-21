class RenameEmailSubscribeToMessageNotificationEmails < ActiveRecord::Migration[5.1]
  def change
    rename_column :users, :email_subscribe, :message_notification_emails
  end
end
