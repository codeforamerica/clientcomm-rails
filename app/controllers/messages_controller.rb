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
      .where('send_at < ? OR send_at IS NULL', Time.now)
      .order('created_at ASC')
    @messages.update_all(read: true)
    # a new message for the form
    @message = Message.new
  end

  def create
    client = current_user.clients.find params[:client_id]

    message = Message.create(message_params.merge({
      user: current_user,
      client: client,
      number_from: ENV['TWILIO_PHONE_NUMBER'],
      number_to: client.phone_number
    }))

    create_message_jobs(message: message)

    if message.send_at.nil?
      label = 'message_send'
    else
      label = 'message_schedule'
    end

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
      .permit(:body, :read, :send_at)
  end

  private

  def create_message_jobs(message:)
    if message.send_at.nil?
      MessageBroadcastJob.perform_now(message: message)

      ScheduledMessageJob.perform_later(message: message, callback_url: incoming_sms_status_url)
    else
      ScheduledMessageJob.set(wait_until: message.send_at).perform_later(message: message, callback_url: incoming_sms_status_url)

      NotificationBroadcastJob.perform_later(
        channel_id: current_user.id,
        text: 'Your message has been scheduled',
        link_to: '#',
        properties: nil
      )
    end
  end
end
