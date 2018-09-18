class MessagesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def download
    rr = current_user.reporting_relationships.find params[:reporting_relationship_id]
    @client = rr.client

    analytics_track(
      label: 'client_messages_transcript_download',
      data: @client.analytics_tracker_data
    )

    # the list of past messages
    @messages = rr.messages
                  .where('send_at < ?', Time.zone.now)
                  .order('send_at ASC')

    transcript = render_to_string file: 'messages/transcript_download.txt'
    send_data transcript.encode(crlf_newline: true), filename: "#{@client.first_name}_#{@client.last_name}_transcript.txt"
  end

  def create
    client = current_user.clients.find params[:client_id]
    rr = ReportingRelationship.find_by(user: current_user, client: client)
    send_at = message_params[:send_at].present? ? DateParser.parse(message_params[:send_at][:date], message_params[:send_at][:time]) : Time.zone.now
    valid_attachments = true
    attachments = message_params[:attachments]&.map do |attachment|
      file = Attachment.new(attachment)
      valid_attachments = false if file.media_file_size > 5000000
      valid_attachments = false unless ['image/jpeg', 'image/png', 'image/gif'].include? file.media_content_type
      file
    end
    attachments ||= []
    message = TextMessage.new(
      reporting_relationship: rr,
      body: message_params[:body],
      number_from: current_user.department.phone_number,
      number_to: client.phone_number,
      send_at: send_at,
      like_message_id: params[:like_message_id],
      read: true,
      attachments: attachments
    )

    if message.invalid? || message.past_message? || !valid_attachments
      @message = message
      @client = client
      @messages = past_messages(client: @client)
      @messages_scheduled = rr.messages.scheduled

      render 'reporting_relationships/show'
      return
    end

    message.save!

    message.send_message

    track_create(message: message, send_at: message_params[:send_at], has_attachment: attachments.any?)

    respond_to do |format|
      format.html { redirect_to reporting_relationship_path(current_user.reporting_relationships.find_by(client: client)) }
      format.js { head :no_content }
    end
  end

  def edit
    @message = current_user.messages.find(params[:id])

    @client = @message.client

    @messages = past_messages(client: @message.client)
    @messages_scheduled = @message.reporting_relationship.messages.scheduled

    analytics_track(
      label: 'message_scheduled_edit_view',
      data: @message.analytics_tracker_data
    )

    render 'reporting_relationships/show'
  end

  def update
    param_body = message_params[:body]
    param_send_at = DateParser.parse(message_params[:send_at][:date], message_params[:send_at][:time])

    @message = Message.find(params[:id])
    @message.body = param_body
    @message.send_at = param_send_at

    if @message.invalid? || @message.past_message?
      @client = @message.client

      @messages = past_messages(client: @client)
      @messages_scheduled = @message.reporting_relationship.messages.scheduled

      render 'reporting_relationships/show'
      return
    end

    @message.save!

    flash[:notice] = 'Your message has been updated'

    rr = current_user.reporting_relationships.find_by(client: @message.client)
    redirect_to reporting_relationship_path(rr)
  end

  def destroy
    @message = Message.find(params[:id])

    @message.destroy!

    analytics_track(
      label: 'message_scheduled_delete',
      data: @message.analytics_tracker_data
    )

    flash[:notice] = 'The scheduled message has been deleted'
    rr = current_user.reporting_relationships.find_by(client: @message.client)
    redirect_to reporting_relationship_path(rr)
  end

  def message_params
    params.require(:message).permit(:body, send_at: [:date, :time], attachments: [:media])
  end

  private

  def default_send_at
    Time.current.beginning_of_day + 9.hours
  end

  def past_messages(client:)
    rr = ReportingRelationship.find_by(user: current_user, client: client)
    rr.messages
      .where('send_at < ?', Time.zone.now)
      .order(send_at: :asc)
  end

  def track_create(message:, send_at:, has_attachment:)
    if send_at.present?
      flash[:notice] = 'Your message has been scheduled'
      analytics_track(
        label: 'message_scheduled',
        data: message.analytics_tracker_data.merge(mass_message: false)
      )
    else
      tracking_data = { mass_message: false }
      tracking_data[:positive_template] = params[:positive_template_type].present?
      tracking_data[:positive_template_type] = params[:positive_template_type]
      tracking_data[:attachment] = has_attachment

      tracking_data[:welcome_template] = false
      if params[:welcome_message_original].present?
        distance = FuzzyMatcher.get_distance(string_a: params[:welcome_message_original], string_b: message.body)
        tracking_data[:welcome_template] = true if distance >= 0.85

        analytics_track(
          label: 'welcome_prompt_send',
          data: message.analytics_tracker_data.merge(tracking_data)
        )
      end

      analytics_track(
        label: 'message_send',
        data: message.analytics_tracker_data.merge(tracking_data)
      )
    end
  end
end
