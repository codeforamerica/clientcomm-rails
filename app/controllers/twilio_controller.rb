class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def incoming_sms

  end

  def incoming_sms_status
    # update the status of the corresponding message in the database
    # TODO: error handling
    message = Message.find_by twilio_sid: params[:SmsSid]
    message.update(twilio_status: params[:SmsStatus])
  end

  def incoming_voice

  end

end
