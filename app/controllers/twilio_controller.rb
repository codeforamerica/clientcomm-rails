class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token
  # validate twilio authenticity using twilio middleware
  # config/application.rb:28

  TWILIO_STATUS_DELIVERED = 'delivered'.freeze
  TWILIO_STATUS_SENT = 'sent'.freeze
  TWILIO_STATUS_UNDELIVERED = 'undelivered'.freeze
  TWILIO_STATUS_FAILED = 'failed'.freeze

  def incoming_sms
    IncomingMessageJob.perform_later(params: incoming_message_params.to_h)

    head :no_content
  end

  def incoming_sms_status
    message = Message.find_by twilio_sid: params[:SmsSid]
    return if message.nil?

    heroku_request_start = request.headers['X-Request-Start']

    message.with_lock do
      if !message.last_twilio_update || heroku_request_start > message.last_twilio_update
        message_incoming_status = params[:SmsStatus]
        message.update!(twilio_status: message_incoming_status, last_twilio_update: heroku_request_start)

        MessageBroadcastJob.perform_later(message: message)

        if [TWILIO_STATUS_DELIVERED, TWILIO_STATUS_SENT].include?(message_incoming_status)
          message.reporting_relationship.update!(has_message_error: false)
        elsif [TWILIO_STATUS_FAILED, TWILIO_STATUS_UNDELIVERED].include?(message_incoming_status)
          message.reporting_relationship.update!(has_message_error: true)
          analytics_track(
            label: 'message_send_failed',
            data: message.analytics_tracker_data
          )
        end
      end
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
                     .find_by(reporting_relationships: { client: client, active: true })

    if user.try(:phone_number).present?
      render xml: voice_client.dial_number(phone_number: user.phone_number)
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
      render xml: voice_client.dial_number(phone_number: unclaimed_number)
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
      render xml: voice_client.generate_text_response(message: t('voice_response'))
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

  def incoming_message_params
    params.permit(:From, :To, :SmsSid, :SmsStatus, :Body, :NumMedia).tap do |whitelisted|
      whitelisted['NumMedia'].to_i.times do |i|
        whitelisted[:"MediaUrl#{i}"] = params[:"MediaUrl#{i}"]
        whitelisted[:"MediaContentType#{i}"] = params[:"MediaContentType#{i}"]
      end
    end
  end
end
