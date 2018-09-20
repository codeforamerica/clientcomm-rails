class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token
  # validate twilio authenticity using twilio middleware
  # config/application.rb:28

  def incoming_sms
    IncomingMessageJob.perform_later(params: incoming_message_params.to_h)

    head :no_content
  end

  def incoming_sms_status
    job_params = incoming_message_params.to_h.merge(
      heroku_request_start: request.headers['X-Request-Start']
    )
    IncomingStatusJob.perform_later(params: job_params)

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
