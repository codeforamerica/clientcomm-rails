require 'singleton'

class VoiceService

  def generate_twiml(message:)
    twiml = Twilio::TwiML::VoiceResponse.new
    twiml.say(message, voice: 'woman')
    twiml.to_s
  end

end
