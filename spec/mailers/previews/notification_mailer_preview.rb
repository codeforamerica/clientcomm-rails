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
    transfer_note = ''

    NotificationMailer.client_transfer_notification(
      current_user: user,
      previous_user: previous_user,
      client: client,
      transfer_note: transfer_note
    )
  end

  def client_edit_notification
    notified_user = User.first
    editing_user = User.last
    phone_number = '408-555-5058'
    full_name = 'Oldname McOldnamerson'
    client = Client.take

    NotificationMailer.client_edit_notification(
      notified_user: notified_user,
      editing_user: editing_user,
      phone_number: phone_number,
      full_name: full_name,
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
