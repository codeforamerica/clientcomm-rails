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
    client = current_user.clients.find params[:client_id]
    merge_params = message_params()

    message = SMSService.instance.send_message(
        current_user,
        params[:client_id],
        params[:message][:body],
        merge_params,
        callback_url: incoming_sms_status_url
    )

    puts message
    label = ['failed', 'undelivered'].include?(message['response'].status) ? 'message_send_failed' : 'message_send'

    analytics_track(
      label: label,
      data: message['new_message'].analytics_tracker_data
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
