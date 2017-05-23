class MessagesController < ApplicationController
  def index
    # the client being messaged
    @client = Client.find params[:client_id]
    # the list of past messages
    @messages = current_user.messages.where(client_id: params["client_id"]).order('created_at ASC')
    # a new message for the form
    @message = Message.new
  end

  def create
    # the client being messaged
    client = Client.find params[:client_id]

    # send the message
    SMSService.instance.send_message(to: client.phone_number, body: params[:message][:body])

    # save the message
    new_message_params = message_params.merge({user: current_user, client: client, number_to: client.phone_number, number_from: ENV['TWILIO_PHONE_NUMBER'], inbound: false})
    Message.create(new_message_params)

    # reload the index
    redirect_to client_messages_path(client.id)
  end

  def message_params
    params.fetch(:message, {})
      .permit(:body)
  end
end
