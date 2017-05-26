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
    response = SMSService.instance.send_message(to: client.phone_number, body: params[:message][:body], callback_url: incoming_sms_status_url)

    # TODO: catch, handle, log errors with response.error_code, response.error_message

    # save the message
    new_message_params = message_params.merge({user: current_user, client: client, number_to: client.phone_number, number_from: ENV['TWILIO_PHONE_NUMBER'], inbound: false, twilio_sid: response.sid, twilio_status: response.status})

    message = Message.create(new_message_params)

    # broadcast the message on ActionCable
    message_html = render_to_string partial: 'messages/message', locals: {message: message}
    ActionCable.server.broadcast "messages_#{message.client_id}",
      message_html: message_html

    # reload the index
    redirect_to client_messages_path(client.id)
  end

  def message_params
    params.fetch(:message, {})
      .permit(:body)
  end
end
