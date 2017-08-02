class MessagesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def index
    @client = current_user.clients.find params[:client_id]

    analytics_track(
      label: 'client_messages_view',
      data: @client.analytics_tracker_data
    )

    # the list of past messages
    @messages = past_messages(client: @client)
    @messages.update_all(read: true)

    @messages_scheduled = scheduled_messages(client: @client)

    @message = Message.new(send_at: DateTime.now.beginning_of_day + 9.hours)

    render :index, locals: {
        back_link: client_messages_path(@client),
        modal_title: 'Send message later',
        submit_text: 'Schedule message',
        send_autofocus: true,
        edit_autofocus: false
    }
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
    if message_params[:send_at].present?
      return unless is_valid(message_params[:send_at])
    end

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
    @message = current_user.messages.find(params[:id])

    @client = @message.client

    @messages = past_messages(client: @message.client)
    @messages_scheduled = scheduled_messages(client: @client)

    render :index, locals: {
        back_link: client_scheduled_messages_index_path(@client),
        modal_title: 'Edit your message',
        submit_text: 'Update',
        send_autofocus: false,
        edit_autofocus: true
    }
  end

  def update
    @message = Message.find(params[:id])
    @message.update(body: message_params[:body])

    @message.send_at = Time.zone.strptime("#{message_params[:send_at][:date]} #{message_params[:send_at][:time]}", '%m/%d/%Y %H:%M%P') unless message_params[:send_at].nil?

    @message.save!

    create_message_jobs(message: @message)

    redirect_to client_messages_path(@message.client)
  end

  def destroy
    @message = Message.find(params[:id])

    @message.destroy

    redirect_to client_messages_path(@message.client)
  end

  def message_params
    params.require(:message).permit(:body, send_at: [:date, :time])
  end

  private

  def scheduled_messages(client:)
    current_user.messages
        .where(client: client)
        .where('send_at >= ?', Time.now)
        .order('created_at ASC')
  end

  def past_messages(client:)
    current_user.messages
        .where(client: client)
        .where('send_at < ? OR send_at IS NULL', Time.now)
        .order('created_at ASC')
  end

  def create_message_jobs(message:)
    if message.send_at.nil?
      MessageBroadcastJob.perform_now(message: message)

      ScheduledMessageJob.perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)
    else
      ScheduledMessageJob.set(wait_until: message.send_at).perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)

      flash[:notice] = 'Your message has been scheduled'
    end
  end

  def is_valid(send_at)
    Time.zone.strptime("#{send_at[:date]} #{send_at[:time]}", '%m/%d/%Y %H:%M%P')

    true
  rescue ArgumentError
    false
  end
end
