# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  def message_notification
    message = Message.first
    # message = Message.find(LegacyAttachment.first.message_id)
    user = message.user
    NotificationMailer.message_notification(user, message)
  end
end
