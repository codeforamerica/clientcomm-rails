class MessagesController < ApplicationController
  before_action :authenticate_user!

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

    # send the message via Twilio
    response = SMSService.instance.send_message(
      to: client.phone_number,
      body: params[:message][:body],
      callback_url: incoming_sms_status_url
    )

    # TODO: catch, handle, log errors with response.error_code, response.error_message

    # save the message
    new_message_params = message_params.merge({
      client: client,
      user: current_user,
      number_to: client.phone_number,
      number_from: ENV['TWILIO_PHONE_NUMBER'],
      inbound: false,
      twilio_sid: response.sid,
      twilio_status: response.status
    })
    new_message = Message.create(new_message_params)

    # put the message broadcast in the queue
    MessageBroadcastJob.perform_later(new_message)

    # reload the index
    redirect_to client_messages_path(client.id)
  end

  def message_params
    params.fetch(:message, {})
      .permit(:body)
  end
end
