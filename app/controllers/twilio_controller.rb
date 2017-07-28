class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def incoming_sms
    new_message = Message.create_from_twilio! params
    client = new_message.client

    # queue message and notification broadcasts
    MessageBroadcastJob.perform_later(message: new_message)

    # construct and queue an alert
    message_alert = MessageAlertBuilder.build_alert(user: client.user)
    NotificationBroadcastJob.perform_later(
      channel_id: client.user_id,
      text: message_alert[:text],
      link_to: message_alert[:link_to],
      properties: { client_id: client.id }
    )

    NotificationMailer.message_notification(client.user, new_message).deliver_later if client.user.email_subscribe

    analytics_track(
      label: 'message_receive',
      data: new_message.analytics_tracker_data
    )

    head :no_content
  end

  def incoming_sms_status
    # update the status of the corresponding message in the database
    message = Message.find_by twilio_sid: params[:SmsSid]
    message.update(twilio_status: params[:SmsStatus])

    # put the message broadcast in the queue
    MessageBroadcastJob.perform_later(message: message)

    # track failed messages
    if ['failed', 'undelivered'].include?(params[:SmsStatus])
      analytics_track(
        label: 'message_send_failed',
        data: message.analytics_tracker_data
      )
    end

    head :no_content
  end

  def incoming_voice

  end

end
