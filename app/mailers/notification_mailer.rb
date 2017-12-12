class NotificationMailer < ApplicationMailer
  def message_notification(user, message)
    @client = message.client
    @message = message

    mail(
      to: user.email,
      subject: "New text message from #{@client.first_name} #{@client.last_name} on ClientComm"
    )
  end

  def client_transfer_notification(current_user:, previous_user:, client:)
    @current_user = current_user
    @previous_user = previous_user
    @client = client

    mail(
      to: @current_user.email,
      subject: 'You have a new client on ClientComm'
    )
  end

  def client_edit_notification(notified_user:, editing_user:, phone_number: nil, full_name: nil, client:)
    @notified_user = notified_user
    @editing_user = editing_user
    @phone_number = phone_number
    @full_name = full_name
    @client = client

    mail(
      to: @notified_user.email,
      subject: "Your client's contact information has been updated"
    )
  end

  def batch_transfer_notification(current_user:, transferred_clients:)
    @current_user = current_user
    @transferred_clients = transferred_clients

    mail(
      to: @current_user.email,
      subject: "You have #{@transferred_clients.count} new clients on ClientComm"
    )
  end
end
