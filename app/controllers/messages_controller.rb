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
    # send the message
    client = current_user.clients.find params[:client_id]

    message = Message.create(message_params.merge({
      user: current_user,
      client: client,
      number_from: ENV['TWILIO_PHONE_NUMBER'],
      number_to: client.phone_number
    }))

    send_date = message.send_date || Time.now

    MessageBroadcastJob.perform_now(message: message, is_update: false)

    ScheduledMessageJob.set(wait_until: send_date).perform_later(message: message, callback_url: incoming_sms_status_url)
    # track the message send

    label = 'message_sent_immediately'

    analytics_track(
      label: label,
      data: message.analytics_tracker_data
    )

    respond_to do |format|
      format.html { redirect_to client_messages_path(client.id) }
      format.js { head :no_content }
    end
  end

  def message_params
    params.require(:message)
      .permit(:body, :read, :send_date)
  end
end
