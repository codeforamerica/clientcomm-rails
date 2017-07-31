# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  def message_notification
    message = Message.where(client: client, user: user).first
    # message = Message.find(Attachment.first.message_id)
    user = message.user
    NotificationMailer.message_notification(user, message)
  end
end
