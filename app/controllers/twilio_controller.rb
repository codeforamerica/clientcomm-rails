class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def incoming_sms
    new_message = Message.create_from_twilio! params
    client = new_message.client

    rr = client.reporting_relationships.find_or_create_by(user: new_message.user)

    client_previously_active = rr.active

    client.update!(
      last_contacted_at: new_message.send_at,
      has_unread_messages: true,
      has_message_error: false
    )

    rr.update!(active: true)

    MessageRedactionJob.perform_later(message: new_message)

    # queue message and notification broadcasts
    MessageBroadcastJob.perform_later(message: new_message)

    # construct and queue an alert
    message_alert = MessageAlertBuilder.build_alert(
      user: new_message.user,
      client_messages_path: client_messages_path(client.id),
      clients_path: clients_path
    )

    NotificationBroadcastJob.perform_later(
      channel_id: new_message.user_id,
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

    # update the status of the corresponding message in the database
    # reload before `update` to avoid any DB race conditions from optimistic locking
    message.reload.update!(twilio_status: params[:SmsStatus])

    # put the message broadcast in the queue
    MessageBroadcastJob.perform_later(message: message)

    if params[:SmsStatus] == 'delivered'
      message.client.update!(has_message_error: false)
      SMSService.instance.redact_message(message: message)
    elsif ['failed', 'undelivered'].include?(params[:SmsStatus])
      message.client.update!(has_message_error: true)
      SMSService.instance.redact_message(message: message)
      analytics_track(
        label: 'message_send_failed',
        data: message.analytics_tracker_data
      )
    end
  end

  def incoming_voice
    voice_client = VoiceService.new
    client = Client.find_by(phone_number: params['From'])
    client_id = client.try(:id) || 'no client'
    user = User.joins(:department)
             .joins(:reporting_relationships)
             .where(departments: { phone_number: params['To'] })
             .find_by(reporting_relationships: { client: client })

    if user.try(:phone_number).present?
      render :xml => voice_client.dial_number(phone_number: user.phone_number)
      analytics_track(
        label: 'phonecall_receive',
        data: {
          client_id: client_id,
          client_identified: user.present? && (user.email != ENV['UNCLAIMED_EMAIL']),
          call_routed: true,
          has_desk_phone: true
        }
      )
    elsif (unclaimed_number = User.find_by_email(ENV['UNCLAIMED_EMAIL']).try(:phone_number))
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
end
