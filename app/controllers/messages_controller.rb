class MessagesController < ApplicationController
  include ScheduledMessagesHelper

  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  DEFAULT_SEND_AT = Time.current.beginning_of_day + 9.hours

  def index
    @client = current_user.clients.find params[:client_id]

    analytics_track(
      label: 'client_messages_view',
      data: @client.analytics_tracker_data
    )

    # the list of past messages
    @messages = past_messages(client: @client)
    @messages.update_all(read: true)

    @message = Message.new(send_at: DEFAULT_SEND_AT)
    @sendfocus = true

    @messages_scheduled = scheduled_messages(client: @client)
  end

  def download
    @client = current_user.clients.find params[:client_id]

    analytics_track(
        label: 'client_messages_transcript_download',
        data: @client.analytics_tracker_data
    )

    # the list of past messages
    @messages = current_user.messages
                    .where(client_id: params["client_id"])
                    .where('send_at < ? OR send_at IS NULL', Time.now)
                    .order('created_at ASC')

    transcript = render_to_string file: 'messages/transcript_download.txt'

    send_data transcript, filename: "#{@client.first_name}_#{@client.last_name}_transcript.txt"
  end

  def create
    param_body = message_params[:body]
    param_send_at = Time.current
    analytics_label = 'message_send'
    if message_params[:send_at].present?
      param_send_at = DateParser.parse(message_params[:send_at][:date], message_params[:send_at][:time])
      analytics_label = 'message_scheduled'
      @message = Message.new(
          body: param_body,
          send_at: param_send_at
      )

      if @message.invalid?
        @client = current_user.clients.find params[:client_id]

        @messages = past_messages(client: @client)
        @messages_scheduled = scheduled_messages(client: @client)

        render :index
        return
      end
    end

    client = current_user.clients.find params[:client_id]

    message = Message.new(
      body: param_body,
      user: current_user,
      client: client,
      number_from: ENV['TWILIO_PHONE_NUMBER'],
      number_to: client.phone_number,
      read: true,
      send_at: param_send_at
    )
    message.save!

    if message_params[:send_at].present?
      ScheduledMessageJob.set(wait_until: message.send_at).perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)
      flash[:notice] = 'Your message has been scheduled'
    else
      MessageBroadcastJob.perform_now(message: message)
      ScheduledMessageJob.perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)
    end

    analytics_track(
      label: analytics_label,
      data: message.analytics_tracker_data
    )

    respond_to do |format|
      format.html { redirect_to client_messages_path(client.id) }
      format.js { head :no_content }
    end
  end

  def edit
    @message = current_user.messages.find(params[:id])

    @client = @message.client

    @messages = past_messages(client: @message.client)
    @messages_scheduled = scheduled_messages(client: @client)

    analytics_track(
      label: 'message_scheduled_edit_view',
      data: @message.analytics_tracker_data
    )

    render :index
  end

  def update
    param_body = message_params[:body]
    param_send_at = DateParser.parse(message_params[:send_at][:date], message_params[:send_at][:time])
    @message = Message.find(params[:id])
    @message.body = param_body
    @message.send_at = param_send_at

    if @message.invalid?
      @client = @message.client

      @messages = past_messages(client: @client)
      @messages_scheduled = scheduled_messages(client: @client)

      render :index
      return
    end

    @message.save!

    ScheduledMessageJob.set(wait_until: @message.send_at).perform_later(message: @message, send_at: @message.send_at.to_i, callback_url: incoming_sms_status_url)

    flash[:notice] = 'Your message has been updated'

    redirect_to client_messages_path(@message.client)
  end

  def destroy
    @message = Message.find(params[:id])

    @message.destroy!

    analytics_track(
      label: 'message_scheduled_delete',
      data: @message.analytics_tracker_data
    )

    flash[:notice] = 'The scheduled message has been deleted'
    redirect_to client_messages_path(@message.client)
  end

  def message_params
    params.require(:message).permit(:body, send_at: [:date, :time])
  end

  private

  def past_messages(client:)
    current_user.messages
        .where(client: client)
        .where('send_at < ?', Time.now)
        .order('created_at ASC')
  end
end
