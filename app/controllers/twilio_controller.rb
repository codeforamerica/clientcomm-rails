class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def incoming_sms
    new_message = Message.create_from_twilio! params
    client = new_message.client

    # queue message and notification broadcasts
    MessageBroadcastJob.perform_later(message: new_message, is_update: false)

    # construct and queue an alert
    message_alert = MessageAlertBuilder.build_alert(user: client.user)
    NotificationBroadcastJob.perform_later(
      text: message_alert[:text],
      link_to: message_alert[:link_to],
      client: client
    )

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
    MessageBroadcastJob.perform_later(message: message, is_update: true)

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
