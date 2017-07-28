class NotificationMailer < ApplicationMailer
  def message_notification(user, message)
    @client = message.client
    @message = message

    mail(
        to: user.email,
        subject: "New text message from #{@client.first_name} #{@client.last_name} on ClientComm"
    )
  end
end
