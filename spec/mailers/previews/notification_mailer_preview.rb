# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  def message_notification
    user = User.first
    client = user.clients.first
    message = Message.where(client: client, user: user).first
    NotificationMailer.message_notification(user, message)
  end
end
