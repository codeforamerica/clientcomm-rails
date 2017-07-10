class MessagesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def index
    # the client being messaged
    @client = current_user.clients.find params[:client_id]

    analytics_track(
      label: 'client_messages_view',
      data: @client.analytics_tracker_data
    )

    # the list of past messages
    @messages = current_user.messages
      .where(client_id: params["client_id"])
      .order('created_at ASC')
    @messages.update_all(read: true)
    # a new message for the form
    @message = Message.new
  end

  def create
    # the client being messaged
    client = current_user.clients.find params[:client_id]

    # send the message via Twilio
    response = SMSService.instance.send_message(
      to: client.phone_number,
      body: params[:message][:body],
      callback_url: incoming_sms_status_url
    )

    # save the message
    new_message_params = message_params.merge({
      client: client,
      inbound: false,
      number_from: ENV['TWILIO_PHONE_NUMBER'],
      number_to: client.phone_number,
      read: true,
      twilio_sid: response.sid,
      twilio_status: response.status,
      user: current_user
    })
    new_message = Message.create(new_message_params)

    # put the message broadcast in the queue
    MessageBroadcastJob.perform_now(message: new_message, is_update: false)

    label = ['failed', 'undelivered'].include?(response.status) ? 'message_send_failed' : 'message_send'
    analytics_track(
      label: label,
      data: new_message.analytics_tracker_data
    )

    respond_to do |format|
      format.html { redirect_to client_messages_path(client.id) }
      format.js { head :no_content }
    end
  end

  def message_params
    params.fetch(:message, {})
      .permit(:body, :read)
  end
end
