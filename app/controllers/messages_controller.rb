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

    @messages_scheduled = current_user.messages
      .where(client_id: params["client_id"])
      .where('send_at >= ?', Time.now)
      .order('created_at ASC')

    @message = Message.new
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
    client = current_user.clients.find params[:client_id]

    message = Message.new(
      body: message_params[:body],
      user: current_user,
      client: client,
      number_from: ENV['TWILIO_PHONE_NUMBER'],
      number_to: client.phone_number,
      read: true
    )

    message.send_at = Time.zone.strptime("#{message_params[:send_at][:date]} #{message_params[:send_at][:time]}", '%m/%d/%Y %H:%M%P') unless message_params[:send_at].nil?

    message.save!

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

  def edit
    @message = Message.find(params[:id])

    @client = @message.client

    analytics_track(
      label: 'client_messages_view',
      data: @client.analytics_tracker_data
    )

    # the list of past messages
    @messages = current_user.messages
      .where(client: @message.client)
      .where('send_at < ? OR send_at IS NULL', Time.now)
      .order('created_at ASC')

    # TODO use scheduled_messages_helper for this
    @messages_scheduled = current_user.messages
      .where(client_id: params["client_id"])
      .where('send_at >= ?', Time.now)
      .order('created_at ASC')
  end

  def update
    @message = Message.find(params[:id])
    @message.update(body: message_params[:body])

    @message.send_at = Time.zone.strptime("#{message_params[:send_at][:date]} #{message_params[:send_at][:time]}", '%m/%d/%Y %H:%M%P') unless message_params[:send_at].nil?

    @message.save!

    create_message_jobs(message: @message)

    redirect_to client_messages_path(@message.client)
  end

  def message_params
    params.require(:message).permit(:body, send_at: [:date, :time])
  end

  private

  def create_message_jobs(message:)
    if message.send_at.nil?
      MessageBroadcastJob.perform_now(message: message)

      ScheduledMessageJob.perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)
    else
      ScheduledMessageJob.set(wait_until: message.send_at).perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)

      flash[:notice] = 'Your message has been scheduled'
    end
  end
end
