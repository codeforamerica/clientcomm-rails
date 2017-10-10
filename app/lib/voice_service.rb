require 'singleton'

class VoiceService

  def generate_text_response(message:)
    twiml = Twilio::TwiML::VoiceResponse.new
    twiml.say(message, voice: 'woman')
    twiml.to_s
  end

  def dial_number(phone_number:)
    twiml = Twilio::TwiML::VoiceResponse.new
    twiml.dial do |dial|
      dial.number(phone_number)
    end
    twiml.to_s
  end

end
