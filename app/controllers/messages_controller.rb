class MessagesController < ApplicationController
  include ScheduledMessagesHelper

  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def index
    @client = current_user.clients.find params[:client_id]

    analytics_track(
      label: 'client_messages_view',
      data: @client.analytics_tracker_data
    )

    @templates = current_user.templates

    # the list of past messages
    @messages = past_messages(client: @client)
    @messages.update_all(read: true)

    @client.update(has_unread_messages: false)

    @message = Message.new(send_at: default_send_at)
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
                            .where(client_id: params['client_id'])
                            .where('send_at < ?', Time.now)
                            .order('send_at ASC')

    transcript = render_to_string file: 'messages/transcript_download.txt'
    send_data transcript.encode(crlf_newline: true), filename: "#{@client.first_name}_#{@client.last_name}_transcript.txt"
  end

  def create
    client = current_user.clients.find params[:client_id]
    send_at = message_params[:send_at].present? ? DateParser.parse(message_params[:send_at][:date], message_params[:send_at][:time]) : Time.now
    @templates = current_user.templates

    message = Message.new(
      body: message_params[:body],
      user: current_user,
      client: client,
      number_from: current_user.department.phone_number,
      number_to: client.phone_number,
      send_at: send_at,
      read: true
    )

    if message.invalid? | message.past_message?
      @message = message
      @client = client
      @messages = past_messages(client: @client)
      @messages_scheduled = scheduled_messages(client: @client)

      render :index
      return
    end

    message.save!

    if message_params[:send_at].present?
      flash[:notice] = 'Your message has been scheduled'

      analytics_track(
        label: 'message_scheduled',
        data: message.analytics_tracker_data
      )
      ScheduledMessageJob.set(wait_until: message.send_at).perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)
    else
      MessageBroadcastJob.perform_now(message: message)

      analytics_track(
        label: 'message_send',
        data: message.analytics_tracker_data
      )
      ScheduledMessageJob.perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)
    end

    respond_to do |format|
      format.html { redirect_to client_messages_path(client.id) }
      format.js { head :no_content }
    end
  end

  def edit
    @message = current_user.messages.find(params[:id])
    @templates = current_user.templates

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
    @templates = current_user.templates

    @message = Message.find(params[:id])
    @message.body = param_body
    @message.send_at = param_send_at

    if @message.invalid? || @message.past_message?
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

  def default_send_at
    Time.current.beginning_of_day + 9.hours
  end

  def past_messages(client:)
    client.messages
          .where(user: current_user)
          .where('send_at < ?', Time.now)
          .order('send_at ASC')
  end
end
