require 'singleton'

class VoiceService

  def generate_twiml(message:)
    Twilio::TwiML::Response.new do |r|
      r.Say(message, voice: 'woman')
    end.text
  end

end
