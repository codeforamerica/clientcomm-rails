class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token
  # validate twilio authenticity using twilio middleware
  # config/application.rb:28

  def incoming_sms
    new_message = Message.create_from_twilio! params
    client = new_message.client

    rr = client.reporting_relationships.find_or_create_by(user: new_message.user)

    client_previously_active = rr.active

    rr.update!(
      last_contacted_at: new_message.send_at,
      has_unread_messages: true,
      has_message_error: false,
      active: true
    )

    MessageRedactionJob.perform_later(message: new_message)

    # queue message and notification broadcasts
    MessageBroadcastJob.perform_later(message: new_message)

    # construct and queue an alert
    message_alert = MessageAlertBuilder.build_alert(
      reporting_relationship: rr,
      reporting_relationship_path: reporting_relationship_path(rr),
      clients_path: clients_path
    )

    NotificationBroadcastJob.perform_later(
      channel_id: new_message.user.id,
      text: message_alert[:text],
      link_to: message_alert[:link_to],
      properties: { client_id: client.id }
    )

    NotificationMailer.message_notification(new_message.user, new_message).deliver_later if new_message.user.message_notification_emails

    analytics_track(
      label: 'message_receive',
      data: new_message.analytics_tracker_data.merge(client_active: client_previously_active)
    )

    head :no_content
  end

  def incoming_sms_status
    message = Message.find_by twilio_sid: params[:SmsSid]
    return if message.nil?

    attempt_consistency message

    # put the message broadcast in the queue
    MessageBroadcastJob.perform_later(message: message)

    if params[:SmsStatus] == 'delivered'
      message.reporting_relationship.update!(has_message_error: false)
    elsif ['failed', 'undelivered'].include?(params[:SmsStatus])
      message.reporting_relationship.update!(has_message_error: true)
      analytics_track(
        label: 'message_send_failed',
        data: message.analytics_tracker_data
      )
    end

    head :no_content
  end

  def incoming_voice
    voice_client = VoiceService.new
    client = Client.find_by(phone_number: params['From'])
    client_id = client.try(:id) || 'no client'
    department = Department.find_by(phone_number: params['To'])
    user = department.users
                     .joins(:reporting_relationships)
                     .find_by(reporting_relationships: { client: client })

    if user.try(:phone_number).present?
      render :xml => voice_client.dial_number(phone_number: user.phone_number)
      analytics_track(
        label: 'phonecall_receive',
        data: {
          client_id: client_id,
          client_identified: user.present? && (user != department.unclaimed_user),
          call_routed: true,
          has_desk_phone: true
        }
      )
    elsif (unclaimed_number = department.unclaimed_user.try(:phone_number))
      render :xml => voice_client.dial_number(phone_number: unclaimed_number)
      analytics_track(
        label: 'phonecall_receive',
        data: {
          client_id: client_id,
          client_identified: user.present?,
          call_routed: true,
          has_desk_phone: false
        }
      )
    else
      render :xml => voice_client.generate_text_response(message: t('voice_response'))
      analytics_track(
        label: 'phonecall_receive',
        data: {
          client_id: client_id,
          client_identified: user.present?,
          call_routed: false,
          has_desk_phone: false
        }
      )
    end
  end

  private

  def attempt_consistency(message)
    request_start = request.headers['X-Request-Start']
    # update the status of the corresponding message in the database
    # reload before `update` to avoid any DB race conditions from optimistic locking
    Retrier.new retries: 5, errors: [ActiveRecord::StaleObjectError] do
      if !message.last_twilio_update || request_start > message.reload.last_twilio_update
        message.update!(twilio_status: params[:SmsStatus], last_twilio_update: request_start)
      end
    end
  end
end
