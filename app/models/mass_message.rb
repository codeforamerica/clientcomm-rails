class MassMessage
  include ActiveModel::Model
  # For validations see:
  # http://railscasts.com/episodes/219-active-model?view=asciicast

  attr_accessor :user, :message, :clients

  def send_to_all
    clients.reject! { |item| item.empty? }
    clients.each do |client_id|

      client = Client.find(client_id)

      message_params = {
        body: message,
        user: user,
        client: client,
        number_from: ENV['TWILIO_PHONE_NUMBER'],
        number_to: client.phone_number,
        read: true,
        inbound: false,
        send_at: Time.now
      }

      Message.create!(message_params)
    end
  end
end
