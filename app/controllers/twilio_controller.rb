class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def incoming_sms

  end

  def incoming_voice

  end

end
