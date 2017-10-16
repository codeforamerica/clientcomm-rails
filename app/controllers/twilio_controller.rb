class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def incoming_sms
    new_message = Message.create_from_twilio! params
    client = new_message.client

    client_previously_active = client.active

    client.update!(
      active: true,
      last_contacted_at: new_message.send_at,
      has_unread_messages: true,
      has_message_error: false
    )

    MessageRedactionJob.perform_later(message: new_message)

    # queue message and notification broadcasts
    MessageBroadcastJob.perform_later(message: new_message)

    # construct and queue an alert
    message_alert = MessageAlertBuilder.build_alert(
      user: client.user,
      client_messages_path: client_messages_path(client.id),
      clients_path: clients_path
    )

    NotificationBroadcastJob.perform_later(
      channel_id: client.user_id,
      text: message_alert[:text],
      link_to: message_alert[:link_to],
      properties: { client_id: client.id }
    )

    NotificationMailer.message_notification(client.user, new_message).deliver_later if client.user.email_subscribe

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
    message.update!(twilio_status: params[:SmsStatus])

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
    user = Client.find_by(phone_number: params['From']).try(:user)

    if user.try(:phone_number).present?
      render :xml => voice_client.dial_number(phone_number: user.phone_number)
    elsif (unclaimed_number = User.find_by_email(ENV['UNCLAIMED_EMAIL']).try(:phone_number))
      render :xml => voice_client.dial_number(phone_number: unclaimed_number)
    else
      render :xml => voice_client.generate_text_response(message: t('voice_response'))
    end
  end

end
