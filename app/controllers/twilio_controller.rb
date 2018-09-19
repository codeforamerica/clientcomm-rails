class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token
  # validate twilio authenticity using twilio middleware
  # config/application.rb:28

  def incoming_sms
    IncomingMessageJob.perform_later(params: incoming_message_params.to_h)

    head :no_content
  end

  def incoming_sms_status
    Rails.logger.tagged('incoming_sms_status') { Rails.logger.warn "#{params[:SmsSid]} ... params[:SmsSid]: #{params[:SmsStatus]}" }
    message = Message.find_by twilio_sid: params[:SmsSid]
    return if message.nil?

    message.with_lock do
      request_start = request.headers['X-Request-Start']
      Rails.logger.tagged('incoming_sms_status') { Rails.logger.warn "#{params[:SmsSid]} ... request.headers['X-Request-Start']: #{request_start} ... message.last_twilio_update: #{message.last_twilio_update}" }

      if !message.last_twilio_update || request_start > message.last_twilio_update
        Rails.logger.tagged('incoming_sms_status') { Rails.logger.warn "#{params[:SmsSid]} ... updating message.twilio_status to #{params[:SmsStatus]}" }
        message.update!(twilio_status: params[:SmsStatus], last_twilio_update: request_start)
      end

      MessageBroadcastJob.perform_later(message: message)

      if params[:SmsStatus] == 'delivered'
        Rails.logger.tagged('incoming_sms_status') { Rails.logger.warn "#{params[:SmsSid]} ... updating reporting_relationship.has_message_error to FALSE because status is #{params[:SmsStatus]}" }
        message.reporting_relationship.update!(has_message_error: false)
      elsif ['failed', 'undelivered'].include?(params[:SmsStatus])
        Rails.logger.tagged('incoming_sms_status') { Rails.logger.warn "#{params[:SmsSid]} ... updating reporting_relationship.has_message_error to TRUE because status is #{params[:SmsStatus]}" }
        message.reporting_relationship.update!(has_message_error: true)
        analytics_track(
          label: 'message_send_failed',
          data: message.analytics_tracker_data
        )
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
