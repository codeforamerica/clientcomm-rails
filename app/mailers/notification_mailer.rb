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
    @previous_user = previous_user
    @client = client

    mail(
      to: current_user.email,
      subject: 'You have a new client on ClientComm'
    )
  end
end
