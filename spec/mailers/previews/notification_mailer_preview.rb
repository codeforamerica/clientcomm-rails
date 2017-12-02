# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  def message_notification
    user = User.first
    message = user.messages.first

    NotificationMailer.message_notification(user, message)
  end

  def client_transfer_notification
    previous_user = User.last
    user = User.first
    client = user.clients.first

    NotificationMailer.client_transfer_notification(
      current_user: user,
      previous_user: previous_user,
      client: client
    )
  end

  def batch_transfer_notification
    previous_user = User.last
    user = User.first

    transferred_clients = []

    user.clients.each do |client|
      transferred_clients << { client: client, previous_user: previous_user }
    end

    NotificationMailer.batch_transfer_notification(
      current_user: user,
      transferred_clients: transferred_clients
    )
  end
end
